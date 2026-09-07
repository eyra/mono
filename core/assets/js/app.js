// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//

import { PDFViewer } from "./pdf_viewer";
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { decode } from "blurhash";
import { urlBase64ToUint8Array } from "./tools";
import { registerAPNSDeviceToken } from "./apns";
import "./100vh-fix";
import { Viewport } from "./viewport";
import { SidePanel } from "./side_panel";
import { Toggle } from "./toggle";
import { Cell } from "./cell";
import { LiveContent, LiveField } from "./live_content";
import { Tab, TabBar, TabBarFit, TabContent, TabFooterItem } from "./tabbed";
import { Clipboard } from "./clipboard";
import { FeldsparApp } from "./feldspar_app";
import { AuthCodeInput } from "./auth_code_input";
import { installAuthSessionHandlers } from "./auth_session";
import { Wysiwyg } from "./wysiwyg";
import { AutoSubmit } from "./auto_submit";
import { ResetScroll } from "./reset_scroll";
import { FullscreenImage } from "./fullscreen_image";
import { Blurhash } from "./blurhash";
import { UserState, getAllUserState } from "./user_state";
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

let Hooks = {
  AuthCodeInput,
  Cell,
  Clipboard,
  FeldsparApp,
  LiveContent,
  LiveField,
  PDFViewer,
  SidePanel,
  Toggle,
  Tab,
  TabBar,
  TabBarFit,
  TabContent,
  TabFooterItem,
  Viewport,
  Wysiwyg,
  AutoSubmit,
  ResetScroll,
  FullscreenImage,
  Blurhash,
  UserState, // Deprecated: Use new user_state architecture (LiveSocket params + event bubbling)
};

let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      LiveContent.onBeforeElUpdated(from, to);
      TabBar.onBeforeElUpdated(from, to);
    },
  },
  params: {
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    viewport: {
      width: window.innerWidth,
      height: window.innerHeight,
    },
    user_state: getAllUserState(),
  },
  hooks: Hooks,
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
