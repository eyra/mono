export const Clipboard = {
  mounted() {
    this.textToCopy = this.el.getAttribute("data-text");

    this.el.addEventListener("click", (event) => {
      event.stopPropagation();
      const textArea = document.createElement("textarea");
      textArea.value = this.textToCopy;
      textArea.setAttribute("readonly", "");
      textArea.style.position = "absolute";
      textArea.style.left = "-9999px";
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
    });
  },
  updated() {
    this.textToCopy = this.el.getAttribute("data-text");
  },
};
