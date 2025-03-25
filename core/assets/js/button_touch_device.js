export const ButtonTouchDevice = {
  mounted() {
    // On apple touch devices, the active state is not triggered immediately.
    // Just adding the `touchstart` circumvents this.
    this.el.addEventListener("touchstart", () => {});
  },
};
