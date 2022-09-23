export class ElementRef {
  constructor(el) {
    this.el = el;
    if (el === null) {
      throw `Wrapped element is null: ${el}`;
    }
  }

  onClick(handle) {
    this.el.addEventListener("click", () => {
      handle();
    });
  }

  onChange(handle) {
    this.el.addEventListener("change", () => {
      handle();
    });
  }

  selectedFile() {
    return this.el.files[0];
  }

  reset() {
    this.el.type = "text";
    this.el.type = "file";
  }

  click() {
    this.el.click();
  }

  hide() {
    if (!this.el.classList.contains("hidden")) {
      this.el.classList.add("hidden");
    }
  }

  show() {
    this.el.classList.remove("hidden");
  }

  child(childId) {
    const child = this.el.querySelector(`#${childId}`);
    if (child === null) {
      throw `Child not found: ${childId}`;
    } else {
      return new ElementRef(child);
    }
  }

  childs(className) {
    let result = [];
    const elements = this.el.getElementsByClassName(className);
    const childs = Array.from(elements);
    return childs.map((child) => new ElementRef(child));
  }
}
