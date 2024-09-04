import _ from "lodash";

let resizeHandler;

export const Viewport = {
  mounted() {
    // Direct push of current window size to properly update view
    this.pushChangeEvent();

    window.addEventListener("resize", (event) => {
      this.pushChangeEvent();
    });
  },

  updated() {
    console.log("[Viewport] updated");
    this.pushChangeEvent();
  },

  pushChangeEvent() {
    console.log("[Viewport] push update event");
    this.pushEvent("viewport_changed", {
      width: window.innerWidth,
      height: window.innerHeight,
    });
  },

  turbolinksDisconnected() {
    window.removeEventListener("resize", resizeHandler);
  },
};
