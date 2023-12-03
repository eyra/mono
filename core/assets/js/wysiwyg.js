import Trix from "trix";

export const Wysiwyg = {
  mounted() {
    console.log("[Wysiwyg] Mounted");
    this.init();
    this.insertTextArea(this.html);
    this.upsert_editor(this.visible);
  },
  updated() {
    console.log("[Wysiwyg] Updated");
    if (!this.el.parentNode.classList.contains("border-primary")) {
      console.log("[Wysiwyg] Reset");
      this.init();
      this.insertTextArea(this.html);
      this.upsert_editor(this.visible);
    }
  },
  init() {
    this.id = this.el.dataset.id;
    this.name = this.el.dataset.name;
    this.target = this.el.dataset.target;
    this.html = this.el.dataset.html;
    this.visible = this.el.dataset.visible != undefined;
    this.locked = this.el.dataset.locked != undefined;
  },
  insertTextArea(html) {
    if (this.textarea != undefined) {
      this.textarea.remove();
    }

    this.textarea = document.createElement("textarea");
    this.textarea.setAttribute("id", this.id);
    this.textarea.setAttribute("name", this.name);
    this.textarea.setAttribute("phx-target", this.target);
    this.textarea.setAttribute("phx-debounce", "1000");
    this.textarea.classList.add("hidden");
    this.textarea.value = html;
    this.el.appendChild(this.textarea);
  },
  upsert_editor(visible) {
    if (visible) {
      this.removeEditor();
      this.insertEditor();
    } else {
      this.removeEditor();
    }
  },
  insertEditor() {
    this.editor = document.createElement("trix-editor");
    this.editor.setAttribute("input", this.textarea.id);
    this.editor.classList.add("min-h-wysiwyg-editor");
    this.editor.classList.add("max-h-wysiwyg-editor");
    this.editor.classList.add("overflow-y-scroll");
    this.editor.setAttribute("phx-debounce", "1000");

    this.container = document.createElement("div");
    this.container.appendChild(this.editor);
    this.el.appendChild(this.container);
    this.editor.addEventListener("trix-change", (e) => {
      this.editor.dispatchEvent(new Event("input", { bubbles: true }));
    });
  },
  removeEditor() {
    if (this.container != undefined) {
      while (this.container.lastElementChild) {
        this.container.removeChild(this.container.lastElementChild);
      }
      this.container.remove();
      this.container = undefined;
    }
  },
};
