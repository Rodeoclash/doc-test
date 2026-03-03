import { Socket } from "phoenix";

const userToken = document
  .querySelector("meta[name='user-token']")
  ?.getAttribute("content");

const socket = new Socket("/socket", { params: { token: userToken } });
socket.connect();

export default socket;
