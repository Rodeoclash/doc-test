import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { nodeDescriptions } from "./editor_nodes";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const outputPath = resolve(__dirname, "node_descriptions.md");
writeFileSync(outputPath, nodeDescriptions + "\n");
