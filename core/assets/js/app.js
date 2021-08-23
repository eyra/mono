// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//

import '@ryangjchandler/spruce'
import "alpine-magic-helpers/dist/component";
import Alpine from "alpinejs";
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { decode } from "blurhash";
import { urlBase64ToUint8Array } from "./tools";
import { registerAPNSDeviceToken } from "./apns";

window.registerAPNSDeviceToken = registerAPNSDeviceToken;


window.blurHash = () => {
  return {
    show: true,
    rendered: false,
    showBlurHash() {
      return this.show !== false;
    },
    hideBlurHash() {
      if (!liveSocket.socket.isConnected()) {
        return;
      }
      this.show = false;
    },
    render() {
      const img = this.$el.getElementsByTagName("img")[0]
      if (img.complete) {
        this.show = false;
        return;
      }
      if (this.rendered) {
        return;
      }
      this.rendered = true;
      const canvas = this.$el.getElementsByTagName("canvas")[0];
      const blurhash = canvas.dataset.blurhash;
      const width = parseInt(canvas.getAttribute("width"), 10);
      const height = parseInt(canvas.getAttribute("height"), 10);
      const pixels = decode(blurhash, width, height);
      const ctx = canvas.getContext("2d");
      const imageData = ctx.createImageData(width, height);
      imageData.data.set(pixels);
      ctx.putImageData(imageData, 0, 0);
    },
  };
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let Hooks = {};

Hooks.NativeWrapper = {
  mounted() {
    window.nativeWrapperHook = this
  },
  toggleSidePanel() {
    console.log("NativeWrapper::toggleSidePanel")
    nativeWrapper.toggleSidePanel({origin: "right"})
    window.dispatchEvent(new CustomEvent("toggle-native-menu", {}))
  }
}

Hooks.PythonUploader = {
  destroyed(){
    this.worker && this.worker.terminate();
  },
  mounted(){
    this.worker = new Worker("/js/pyworker.js");
    this.worker.onerror = console.log;
    this.worker.onmessage = (event) => {
      const { eventType } = event.data;
      if (eventType === "initialized") {
        const script = this.el.getElementsByTagName("code")[0].innerText
        this.worker.postMessage({eventType: "runPython", script })
        // Let the LiveView know everything is ready
        this.el.querySelector(".loading-indicator").hidden = true;
        this.el.querySelector(".step2").hidden = false;
      }
      else if (eventType === "result") {
        this.result = event.data.result;
        this.el.querySelector(".summary").innerText = this.result.summary;
        this.el.querySelector(".extracted").innerHTML = this.result.html;
        this.el.querySelector(".step4").hidden = false;
      }
    }
    // Hook up the process button to the worker
    this.el.addEventListener("click", (event)=>{
      if (event.target.dataset.role !== "process-trigger") {
        return;
      }
      const fileInput = this.el.querySelector("input[type=file]")
      const file = fileInput.files[0];
      const reader = file.stream().getReader();
      const sendToWorker = ({ done, value }) => {
        if (done) {
          this.worker.postMessage({ eventType: "processData" });
          return;
        }
        this.worker.postMessage({ eventType: "data", chunk: value });
        reader.read().then(sendToWorker);
      };
      this.worker.postMessage({ eventType: "initData", size: file.size });
      reader.read().then(sendToWorker);
    })
    // Hook up the share results button
    this.el.addEventListener("change", (event)=>{
      if (event.target.dataset.role !== "file-input") {
        return;
      }

      this.el.querySelector(".step4").hidden = true;
      this.el.querySelector(".step3").hidden = false;
      this.el.querySelector(".script").hidden = false;
    })
    // Hook up the share results button
    this.el.addEventListener("click", (event)=>{
      if (event.target.dataset.role !== "donate-trigger") {
        return;
      }
      this.pushEvent("donate", this.result);
    })
  }
}

let liveSocket = new LiveSocket('/live', Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to)
      }
    }
  },
  params: {
    _csrf_token: csrfToken
  },
  hooks: Hooks
})

window.nativeIOSWrapper = {
  // The native code bridge assumes that handlers have been setup. Seethe docs for more info:
  // https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1537172-add
  //
  // Uncomment each section to enable it.
  setScreenState: (id, state) => {
    window.webkit.messageHandlers.Native.postMessage({
      type: "setScreenState",
      id,
      state,
    });
  },
  openScreen: (info) => {
    if (info.subtype === "push") {
      window.scrollTo(0, -100); // TBD: makes sure new page is scrolled to top, even with transparant top bar (ios)
    }

    window.webkit.messageHandlers.Native.postMessage({
      type: "openScreen",
      ...info,
    });
  },
  pushModal: () => {
    window.webkit.messageHandlers.Native.postMessage({
      type: "pushModal",
    });
  },
  popModal: () => {
    window.webkit.messageHandlers.Native.postMessage({
      type: "popModal",
    });
  },
  updateScreenInfo: (info) => {
    window.webkit.messageHandlers.Native.postMessage({
      type: "updateScreen",
      ...info,
    });
  },
  webReady: (id) => {
    window.webkit.messageHandlers.Native.postMessage({
      type: "webReady",
      id
    });
  },
  toggleSidePanel: (info)=>{
    window.webkit.messageHandlers.Native.postMessage({
      type: "toggleSidePanel",
      ...info
    })
  }
};

const loggingWrapper = {
  setScreenState: (id, info) => {
    console.log(id, info);
  },
  openScreen: (info) => {
    console.log("open screen", info);
  },
  pushModal: () => {
    console.log("push modal screen");
  },
  popModal: () => {
    console.log("pop modal screen");
  },
  updateScreenInfo: (info) => {
    console.log("set screen info", info);
  },
  webReady: (id) => {
    console.log("web ready", id);
  },
  toggleSidePanel: (info) => {
    console.log("toggle side panel", info)
  },
};

const nativeWrapper =
  window.webkit?.messageHandlers !== undefined
    ? nativeIOSWrapper
    : loggingWrapper;

const screenId = (urlString) => {
  const url = new URL(urlString);
  const params = new URLSearchParams(url.search);
  params.delete("_no");
  return `${url.protocol}//${url.host}${url.pathname}?${params.toString()}`;
};

window.addEventListener("phx:page-loading-start", (info) => {
  // other kind options are "error" and "initial"
  console.log("phx:page-loading-start");
  if (info.detail.kind === "redirect") {
    const to = new URL(info.detail.to);
    const nativeOperation = to.searchParams.get("_no");
    console.log("nativeOperation", nativeOperation);
    nativeWrapper.setScreenState(screenId(window.location), {
      scrollPosition: window.scrollY,
    });
    if (nativeOperation === "replace") {
      nativeWrapper.openScreen({
        id: screenId(info.detail.to),
        subtype: "replace",
      });
    } else {
      nativeWrapper.openScreen({
        id: screenId(info.detail.to),
        subtype: "push",
      });
    }
  }
});

const updateState = (state) => {
  window.scroll(0, state?.scrollPosition || 0);
};

window.addEventListener("phx:page-loading-stop", (info) => {
  if (info.detail.kind !== "initial") {
    return;
  }
  const titleNode = document.querySelector("[data-native-title]");
  const title = titleNode?.dataset.nativeTitle || "- no title set -";
  nativeWrapper.updateScreenInfo({
    title,
    id: screenId(info.detail.to),
    rightBarButtons: [{
      title: "Menu",
      action: {id: "toggle-native-menu"},
    }]
  });
  nativeWrapper.webReady(screenId(info.detail.to));
});

window.setScreenFromNative = (screenId, state) => {
  liveSocket.replaceMain(screenId, null, () => {
    setTimeout(() => {
      updateState(state);
    }, 0);
  });
};
window.handleActionFromNative = (action)=>{
  if (action.id === "toggle-native-menu") {
    nativeWrapper.toggleSidePanel({origin: "right"})
    window.dispatchEvent(new CustomEvent("toggle-native-menu", {}))
  }
}

window.setStateFromNative = (state) => {
  updateState(state);
};

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// PWA
//
const pushStore = Spruce.store("push", {registration: "pending"})
const getExistingSubscription = () => {
  return navigator.serviceWorker.ready.then((registration)=> {
    return registration.pushManager.getSubscription().then(subscription=>{
      return {registration, subscription};
    })
  });
}
const registerPushSubscription = (subscription) => {
      console.log("Server", subscription);
  return fetch('/web-push/register', {
    method: 'post',
    headers: {
      'Content-type': 'application/json'
    },
    body: JSON.stringify({
      subscription: subscription
    }),
  }).then(()=>{
    pushStore.registration = "registered"
  });
}


window.registerForPush = ()=>{
  if (!('serviceWorker' in navigator)) {
    alert("Sorry, your browser does not support push")
    return;
  }
  pushStore.registration = "registering"
  getExistingSubscription().then(({registration,subscription})=> {
    if (subscription) {
      // already registered
      return subscription;
    }

    return fetch('/web-push/vapid-public-key').then((response)=>{
      console.log("Vapid", response);
      return response.text()
    }).then((vapidPublicKey)=>{
      // Chrome doesn’t accept the base64-encoded (string) vapidPublicKey yet urlBase64ToUint8Array() is defined in /tools.js
      const convertedVapidKey = urlBase64ToUint8Array(vapidPublicKey);

      return registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: convertedVapidKey
      });
    })
  }).then(registerPushSubscription).catch(e=>{
    pushStore.registration = "denied";
  });
}
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js', {scope: './'})
  .catch((error) => {
    // registration failed
    console.log('Registration failed with ' + error);
  });

  getExistingSubscription().then(({subscription}) => {
    if (subscription) {
      return registerPushSubscription(subscription);
    } else {
      pushStore.registration = "not-registered";
    }
  })
} else {
  Spruce.store("push", {registration: "unavailable"})
}
