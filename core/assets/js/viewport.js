import _ from "lodash";

let resizeHandler;

export const Viewport = {
  mounted() {
    // // Direct push of current window size to properly update view
    // this.pushChangeEvent();

    window.addEventListener("resize", (event) => {
      this.pushChangeEvent();
    });
  },

  updated() {
    console.log("[Viewport] updated");
    // this.pushChangeEvent();
  },

  pushChangeEvent() {
    console.log(
      "[Viewport] push update event",
      window.innerWidth,
      window.innerHeight
    );
    this.pushEvent("viewport_changed", {
      width: window.innerWidth,
      height: window.innerHeight,
    });
  },

  turbolinksDisconnected() {
    window.removeEventListener("resize", resizeHandler);
  },

  sendToServer() {
    const viewport = {
      width: window.innerWidth,
      height: window.innerHeight,
    };

    console.log("[Viewport]", viewport);

    let csrfToken = document
      .querySelector("meta[name='csrf-token']")
      .getAttribute("content");

    if (typeof window.localStorage != "undefined") {
      try {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "/api/viewport", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("x-csrf-token", csrfToken);
        xhr.onreadystatechange = function () {
          console.log(
            "[Viewport] POST onreadystatechange",
            this.status,
            this.readyState
          );
        };
        xhr.send(`{"viewport": "${viewport}"}`);
      } catch (e) {
        console.log("[Viewport] Error while sending viewport to server", e);
      }
    }
  },
};
