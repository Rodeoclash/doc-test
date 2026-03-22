import "./user_socket";
import { hooks as colocatedHooks } from "phoenix-colocated/backend";
import AutoResizeHook from "./hooks/auto_resize";
import EditorHook from "./hooks/editor";
import ResizablePanelHook from "./hooks/resizable_panel";
import ScrollToBottomHook from "./hooks/scroll_to_bottom";
import SubmitOnShortcutHook from "./hooks/submit_on_shortcut";
import { setupLiveSocket } from "./shared";

setupLiveSocket({
  ...colocatedHooks,
  AutoResize: AutoResizeHook,
  Editor: EditorHook,
  ResizablePanel: ResizablePanelHook,
  ScrollToBottom: ScrollToBottomHook,
  SubmitOnShortcut: SubmitOnShortcutHook,
});
