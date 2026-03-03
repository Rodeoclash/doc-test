import "./user_socket"
import { hooks as colocatedHooks } from "phoenix-colocated/backend"
import EditorHook from "./hooks/editor"
import { setupLiveSocket } from "./shared"

setupLiveSocket({ ...colocatedHooks, Editor: EditorHook })
