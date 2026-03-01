import type { Channel } from 'phoenix';
import socket from '../user_socket';

/**
 * Creates a Phoenix channel for the given document.
 * Does not join — the PhoenixChannelProvider handles joining during connect().
 */
export function createDocumentChannel(documentId: string): Channel {
  return socket.channel(`document:${documentId}`, {});
}
