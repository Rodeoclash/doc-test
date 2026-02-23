import { createRoot, type Root } from 'react-dom/client';
import Editor from './Editor';

let root: Root | null = null;

export function mount(el: HTMLElement) {
  root = createRoot(el);
  root.render(<Editor />);
}

export function unmount() {
  root?.unmount();
  root = null;
}
