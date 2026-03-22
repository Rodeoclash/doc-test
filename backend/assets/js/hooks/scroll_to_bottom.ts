const ScrollToBottom = {
  mounted() {
    this.scrollToBottom();
    this.observer = new MutationObserver(() => this.scrollToBottom());
    this.observer.observe(this.el, { childList: true, subtree: true });
    this.resizeHandler = () => this.scrollToBottom();
    document.addEventListener("chat:resize", this.resizeHandler);
  },

  updated() {
    this.scrollToBottom();
  },

  destroyed() {
    this.observer?.disconnect();
    document.removeEventListener("chat:resize", this.resizeHandler);
  },

  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight;
  },
};

export default ScrollToBottom;
