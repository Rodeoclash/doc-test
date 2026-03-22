const AutoResize = {
  mounted() {
    this.el.addEventListener("input", () => this.resize());
    this.resize();
  },

  updated() {
    this.resize();
  },

  resize() {
    this.el.style.height = "auto";
    this.el.style.height = `${this.el.scrollHeight}px`;
    this.el.dispatchEvent(new CustomEvent("chat:resize", { bubbles: true }));
  },
};

export default AutoResize;
