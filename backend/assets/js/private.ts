import "./user_socket";
import { hooks as colocatedHooks } from "phoenix-colocated/backend";
import AutoResize from "./hooks/auto_resize";
import EditorHook from "./hooks/editor";
import ScrollToBottom from "./hooks/scroll_to_bottom";
import { setupLiveSocket } from "./shared";

setupLiveSocket({ ...colocatedHooks, AutoResize, Editor: EditorHook, ScrollToBottom });
