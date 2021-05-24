// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {
  Socket
} from "phoenix"
import topbar from "topbar"
import {
  LiveSocket
} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: csrfToken
  }
})

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: {
    0: "#29d"
  },
  shadowColor: "rgba(0, 0, 0, .3)"
})

const nativeIOSWrapper = {
  // The native code bridge assumes that handlers have been setup. Seethe docs for more info:
  // https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1537172-add
  //
  // Uncomment each section to enable it.
  openScreen: (id) => {
    window.webkit.messageHandlers.Push.postMessage({
      type: "open",
      id,
    })
  },
  pushModal: () => {
    window.webkit.messageHandlers.Push.postMessage({
      type: "modal",
    })
  },
  popModal: () => {
    window.webkit.messageHandlers.Pop.postMessage({
      type: "modal",
    })
  },
  updateScreenInfo: (title) => {
    window.webkit.messageHandlers.UpdateScreen.postMessage({
      title
    })
  }
}

const loggingWrapper = {
  openScreen: (id) => {
    console.log("open screen", id)
  },
  pushModal: () => {
    console.log("push modal screen")
  },
  popModal: () => {
    console.log("pop modal screen")
  },
  updateScreenInfo: (title) => {
    console.log("set screen title", title)
  }
}

const nativeWrapper = window.webkit?.messageHandlers !== undefined ? nativeIOSWrapper : loggingWrapper


window.addEventListener("phx:page-loading-start", info => {
  topbar.show()
  // other kind options are "error" and "initial"
  if (info.detail.kind === "redirect") { 
    const to = new URL(info.detail.to);
    const nativeOperation = to.searchParams.get("_no");
    if (nativeOperation === "push_modal") {
      nativeWrapper.pushModal()
    } else if (nativeOperation === "pop_modal") {
      nativeWrapper.popModal()
    } else {
      nativeWrapper.openScreen(info.detail.to)
    }
  }
})
window.addEventListener("phx:page-loading-stop", info => {
  topbar.hide()
  const nativeSettingsNode = document.querySelector(".native-settings")
  if (nativeSettingsNode) {
    const settings = nativeSettingsNode.dataset
    nativeWrapper.updateScreenInfo(settings.nativeTitle)
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
