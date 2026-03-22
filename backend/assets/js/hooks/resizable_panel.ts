const STORAGE_KEY = "sidebar-width";
const MIN_WIDTH = 192; // 12rem
const MAX_RATIO = 0.5;

const ResizablePanel = {
  mounted() {
    const container = this.el as HTMLElement;
    const panel = container.querySelector<HTMLElement>("[data-resize-panel]");
    if (!panel) return;

    // Create drag handle
    const handle = document.createElement("div");
    handle.className =
      "absolute top-0 bottom-0 cursor-ew-resize z-10 transition-colors";
    handle.style.width = "8px";
    handle.style.left = "-4px";
    handle.addEventListener("mouseenter", () => {
      if (!this.dragging) {
        handle.classList.add("bg-blue-400/30");
      }
    });
    handle.addEventListener("mouseleave", () => {
      if (!this.dragging) {
        handle.classList.remove("bg-blue-400/30");
      }
    });

    // Panel needs relative positioning for the handle
    panel.style.position = "relative";
    panel.prepend(handle);

    this.dragging = false;

    handle.addEventListener("mousedown", (e: MouseEvent) => {
      e.preventDefault();
      this.dragging = true;
      handle.classList.add("bg-blue-400/30");

      const startX = e.clientX;
      const startWidth = panel.offsetWidth;
      const maxWidth = container.offsetWidth * MAX_RATIO;

      const onMouseMove = (moveEvent: MouseEvent) => {
        // Dragging left = wider sidebar (handle is on the left edge)
        const delta = startX - moveEvent.clientX;
        const newWidth = Math.max(
          MIN_WIDTH,
          Math.min(maxWidth, startWidth + delta),
        );
        this.applyWidth(newWidth);
      };

      const onMouseUp = () => {
        this.dragging = false;
        handle.classList.remove("bg-blue-400/30");
        localStorage.setItem(STORAGE_KEY, String(panel.offsetWidth));
        document.removeEventListener("mousemove", onMouseMove);
        document.removeEventListener("mouseup", onMouseUp);
      };

      document.addEventListener("mousemove", onMouseMove);
      document.addEventListener("mouseup", onMouseUp);
    });
  },

  // Set width via CSS variable so it stays in sync with the [data-resize-panel]
  // rule in app.css and the inline <script> in the layout that reads localStorage.
  applyWidth(width: number) {
    document.documentElement.style.setProperty("--sidebar-width", `${width}px`);
  },
};

export default ResizablePanel;
