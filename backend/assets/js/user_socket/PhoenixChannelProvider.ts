import type { Channel } from 'phoenix';
import type { Provider, ProviderAwareness } from '@lexical/yjs';
import * as Y from 'yjs';
import { Awareness, encodeAwarenessUpdate, applyAwarenessUpdate, removeAwarenessStates } from 'y-protocols/awareness';
import * as syncProtocol from 'y-protocols/sync';
import * as encoding from 'lib0/encoding';
import * as decoding from 'lib0/decoding';

// Outer message type bytes matching yrs::sync::protocol constants
const MESSAGE_SYNC = 0;
const MESSAGE_AWARENESS = 1;
const MESSAGE_AUTH = 2;
const MESSAGE_QUERY_AWARENESS = 3;

type EventType = 'sync' | 'status' | 'update' | 'reload';
type EventCallback = (...args: any[]) => void;

/**
 * Yjs Provider that transports sync messages over a Phoenix channel.
 *
 * The DocServer (Yex.DocServer) speaks the standard Yjs sync protocol
 * wrapped with an outer message type byte:
 *   byte 0: message type (0=sync, 1=awareness, 2=auth, 3=query_awareness)
 *   bytes 1+: protocol-specific payload
 *
 * Messages are base64-encoded for transport over the channel's "yjs" event.
 */
export class PhoenixChannelProvider implements Provider {
  awareness: ProviderAwareness;

  private channel: Channel;
  private doc: Y.Doc;
  private _awareness: Awareness;
  private listeners: Map<string, Set<EventCallback>> = new Map();
  private synced = false;
  private channelRef: number | null = null;

  constructor(channel: Channel, doc: Y.Doc) {
    this.channel = channel;
    this.doc = doc;
    this._awareness = new Awareness(doc);

    // Expose awareness as the ProviderAwareness interface
    this.awareness = {
      getLocalState: () => this._awareness.getLocalState(),
      getStates: () => this._awareness.getStates(),
      setLocalState: (state) => this._awareness.setLocalState(state),
      setLocalStateField: (field, value) => this._awareness.setLocalStateField(field, value),
      on: (_type: 'update', cb: () => void) => this._awareness.on('update', cb),
      off: (_type: 'update', cb: () => void) => this._awareness.off('update', cb),
    };
  }

  connect(): void {
    // Listen for incoming messages from the server
    this.channelRef = this.channel.on('yjs', (payload: { data: string }) => {
      this.handleServerMessage(payload.data);
    });

    // Forward local doc updates to the server
    this.doc.on('update', this.handleDocUpdate);

    // Forward local awareness changes to the server
    this._awareness.on('update', this.handleAwarenessUpdate);

    // Join the channel, then initiate sync handshake
    this.channel
      .join()
      .receive('ok', () => {
        this.emit('status', { status: 'connected' });
        this.sendSyncStep1();
      })
      .receive('error', (resp: unknown) => {
        console.error('Failed to join document channel', resp);
        this.emit('status', { status: 'disconnected' });
      });
  }

  disconnect(): void {
    this.doc.off('update', this.handleDocUpdate);
    this._awareness.off('update', this.handleAwarenessUpdate);

    // Clean up awareness state before leaving
    removeAwarenessStates(this._awareness, [this.doc.clientID], 'disconnect');

    if (this.channelRef !== null) {
      this.channel.off('yjs', this.channelRef);
      this.channelRef = null;
    }

    this.channel.leave();
    this.synced = false;
  }

  on(type: EventType, cb: EventCallback): void {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }
    this.listeners.get(type)!.add(cb);
  }

  off(type: EventType, cb: EventCallback): void {
    this.listeners.get(type)?.delete(cb);
  }

  private emit(type: string, ...args: unknown[]): void {
    this.listeners.get(type)?.forEach((cb) => cb(...args));
  }

  /**
   * Send sync step 1 to initiate the handshake.
   * The server will reply with sync step 2 (its state) + its own sync step 1.
   */
  private sendSyncStep1(): void {
    const encoder = encoding.createEncoder();
    encoding.writeVarUint(encoder, MESSAGE_SYNC);
    syncProtocol.writeSyncStep1(encoder, this.doc);
    this.sendMessage(encoding.toUint8Array(encoder));
  }

  /** Encode a Uint8Array as base64 and push to the channel */
  private sendMessage(data: Uint8Array): void {
    const base64 = uint8ArrayToBase64(data);
    this.channel.push('yjs', { data: base64 });
  }

  /** Handle an incoming base64 message from the server */
  private handleServerMessage(base64: string): void {
    const data = base64ToUint8Array(base64);
    const decoder = decoding.createDecoder(data);
    const messageType = decoding.readVarUint(decoder);

    switch (messageType) {
      case MESSAGE_SYNC:
        this.handleSyncMessage(decoder);
        break;
      case MESSAGE_AWARENESS:
        applyAwarenessUpdate(this._awareness, decoding.readVarUint8Array(decoder), this);
        break;
      case MESSAGE_QUERY_AWARENESS:
        this.sendAwarenessUpdate();
        break;
    }
  }

  /** Process sync protocol messages (step1, step2, update) */
  private handleSyncMessage(decoder: decoding.Decoder): void {
    const encoder = encoding.createEncoder();
    encoding.writeVarUint(encoder, MESSAGE_SYNC);

    const syncMessageType = syncProtocol.readSyncMessage(
      decoder,
      encoder,
      this.doc,
      this, // transactionOrigin — used to skip echoing our own updates
    );

    // If readSyncMessage produced a reply (e.g. step2 in response to step1),
    // send it. The encoder will have more than just the message type byte.
    if (encoding.length(encoder) > 1) {
      this.sendMessage(encoding.toUint8Array(encoder));
    }

    // Mark as synced after receiving sync step 2 (the initial state)
    if (syncMessageType === syncProtocol.messageYjsSyncStep2 && !this.synced) {
      this.synced = true;
      this.emit('sync', true);
    }
  }

  /**
   * Called when the local Y.Doc changes.
   * Wraps the update in the sync protocol format and sends to the server.
   */
  private handleDocUpdate = (update: Uint8Array, origin: unknown): void => {
    // Don't echo back updates that came from the server
    if (origin === this) return;

    const encoder = encoding.createEncoder();
    encoding.writeVarUint(encoder, MESSAGE_SYNC);
    syncProtocol.writeUpdate(encoder, update);
    this.sendMessage(encoding.toUint8Array(encoder));
  };

  /** Called when local awareness state changes, forwards to server */
  private handleAwarenessUpdate = (
    { added, updated, removed }: { added: number[]; updated: number[]; removed: number[] },
    origin: unknown,
  ): void => {
    if (origin === 'local') {
      const changedClients = added.concat(updated).concat(removed);
      const encoder = encoding.createEncoder();
      encoding.writeVarUint(encoder, MESSAGE_AWARENESS);
      encoding.writeVarUint8Array(
        encoder,
        encodeAwarenessUpdate(this._awareness, changedClients),
      );
      this.sendMessage(encoding.toUint8Array(encoder));
    }
  };

  /** Send full awareness state to the server */
  private sendAwarenessUpdate(): void {
    const clients = Array.from(this._awareness.getStates().keys());
    if (clients.length > 0) {
      const encoder = encoding.createEncoder();
      encoding.writeVarUint(encoder, MESSAGE_AWARENESS);
      encoding.writeVarUint8Array(
        encoder,
        encodeAwarenessUpdate(this._awareness, clients),
      );
      this.sendMessage(encoding.toUint8Array(encoder));
    }
  }
}

function uint8ArrayToBase64(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function base64ToUint8Array(base64: string): Uint8Array {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}
