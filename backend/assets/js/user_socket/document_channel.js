import socket from "../user_socket"

export function joinDocumentChannel(documentId) {
  const channel = socket.channel(`document:${documentId}`, {})

  channel.on("hello", (payload) => {
    console.log("Server says:", payload.message)
  })

  channel.join()
    .receive("ok", () => console.log(`Joined document:${documentId}`))
    .receive("error", (resp) => console.log("Join failed", resp))

  return channel
}
