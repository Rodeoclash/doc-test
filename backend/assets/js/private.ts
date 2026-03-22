import "./user_socket";
import { hooks as colocatedHooks } from "phoenix-colocated/backend";
import AutoResizeHook from "./hooks/auto_resize";
import EditorHook from "./hooks/editor";
import ScrollToBottomHook from "./hooks/scroll_to_bottom";
import { setupLiveSocket } from "./shared";

setupLiveSocket({
  ...colocatedHooks,
  AutoResize: AutoResizeHook,
  Editor: EditorHook,
  ScrollToBottom: ScrollToBottomHook,
});
