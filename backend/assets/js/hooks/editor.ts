import { mount, unmount } from './editor/index';

export const EditorHook = {
  mounted() {
    mount(this.el);
  },
  destroyed() {
    unmount();
  }
};
