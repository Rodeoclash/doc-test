import { hooks as colocatedHooks } from "phoenix-colocated/backend"
import { setupLiveSocket } from "./shared"

setupLiveSocket({ ...colocatedHooks })
