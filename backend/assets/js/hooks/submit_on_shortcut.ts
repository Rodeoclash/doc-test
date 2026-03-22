// Currently hardcoded to Ctrl+Enter / Cmd+Enter. Could be extended to read
// shortcuts from a data attribute (e.g. data-shortcuts='["ctrl+enter","shift+enter"]')
// to make the hook configurable per form.
const SubmitOnShortcut = {
  mounted() {
    this.handler = (event: KeyboardEvent) => {
      const isSubmitShortcut =
        event.key === "Enter" && (event.ctrlKey || event.metaKey);

      if (isSubmitShortcut) {
        event.preventDefault();
        this.el.dispatchEvent(
          new Event("submit", { bubbles: true, cancelable: true }),
        );
      }
    };

    this.el.addEventListener("keydown", this.handler);
  },

  destroyed() {
    this.el.removeEventListener("keydown", this.handler);
  },
};

export default SubmitOnShortcut;
