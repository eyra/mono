// Gives an element with role="button" the keyboard behaviour of a native
// button: Enter clicks on keydown, Space clicks on keyup and doesn't scroll.
// Keys pressed on a control inside the element are left to that control.
export const KeyboardClick = {
  mounted() {
    this.el.addEventListener("keydown", (event) => {
      if (event.target !== this.el) return;

      if (event.key === "Enter") {
        event.preventDefault();
        this.el.click();
      } else if (event.key === " ") {
        event.preventDefault();
      }
    });

    this.el.addEventListener("keyup", (event) => {
      if (event.target === this.el && event.key === " ") {
        this.el.click();
      }
    });
  },
};
