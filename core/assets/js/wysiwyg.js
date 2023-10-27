import Trix from "trix";

export const Wysiwyg = {
  mounted() {
    const element = document.querySelector("trix-editor");  
    element.editor.element.addEventListener("trix-change", (e) => {
      element.dispatchEvent(new Event("input", {bubbles: true}))
    });
  },
};