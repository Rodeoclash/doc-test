declare module "phoenix_html" {}

declare module "phoenix_live_view" {
  import type { Socket } from "phoenix"

  export class LiveSocket {
    constructor(
      path: string,
      socket: typeof Socket,
      opts?: Record<string, unknown>,
    )
    connect(): void
    enableDebug(): void
    enableLatencySim(ms: number): void
    disableLatencySim(): void
  }
}

declare module "phoenix-colocated/backend" {
  export const hooks: Record<string, object>
}

declare module "../vendor/topbar" {
  const topbar: {
    config(opts: Record<string, unknown>): void
    show(delay?: number): void
    hide(): void
  }
  export default topbar
}
