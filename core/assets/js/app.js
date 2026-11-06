// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//

import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { decode } from "blurhash";
import { urlBase64ToUint8Array } from "./tools";
import { registerAPNSDeviceToken } from "./apns";
import "./100vh-fix";
import { Hooks } from "./hooks";
import { Viewport } from "./viewport";
import { LiveContent } from "./live_content";
import { TabBar } from "./tabbed";
import { installAuthSessionHandlers } from "./auth_session";
import { installButtonLoading } from "./button_loading";
import { getAllUserState } from "./user_state";
window.registerAPNSDeviceToken = registerAPNSDeviceToken;

// Force the active state on iOS touch devices by adding a touchstart
// listener to all elements with the class "touchstart-sensitive"
document.addEventListener("DOMContentLoaded", () => {
  const observer = new MutationObserver(() => {
    const elements = document.querySelectorAll(".touchstart-sensitive");
    elements.forEach((element) => {
      if (!element.classList.contains("touchstart-listener")) {
        element.addEventListener("touchstart", () => {});
        element.classList.add("touchstart-listener");
      }
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
});

window.addEventListener("phx:page-loading-stop", (info) => {
  if (info.detail.kind == "initial") {
    // Timezone is now passed via LiveSocket params
    Viewport.sendToServer();
  }
});

// Listen for open_url events from server to open URLs in new tab
window.addEventListener("phx:open_url", (event) => {
  const { url } = event.detail;
  window.open(url, "_blank");
});

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

installAuthSessionHandlers({ csrfToken });
installButtonLoading();

let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      LiveContent.onBeforeElUpdated(from, to);
      TabBar.onBeforeElUpdated(from, to);
    },
  },
  // Function: LiveView calls it on every (re)join, so user_state and viewport
  // are current after a reconnect (e.g. iOS suspending the WebSocket).
  params: () => ({
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    viewport: {
      width: window.innerWidth,
      height: window.innerHeight,
    },
    user_state: getAllUserState(),
  }),
  hooks: Hooks,
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
