export const TouchstartSensitive = {
  mounted() {
    // On apple touch devices, the active state is not triggered immediately.
    // Just adding the `touchstart` circumvents this.
    this.parse_all_elements();
  },
  updated() {
    this.parse_all_elements();
  },
  parse_all_elements() {
    const elements = document.querySelectorAll(".touchstart-sensitive");
    elements.forEach((element) => {
      if (!element.classList.contains("touchstart-listener")) {
        element.addEventListener("touchstart", () => {});
        element.classList.add("touchstart-listener");
      }
    });
  },
};
