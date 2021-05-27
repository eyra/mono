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

import 'alpine-magic-helpers/dist/component'
import Alpine from "alpinejs"
import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { decode } from "blurhash";
import {urlBase64ToUint8Array} from "./tools"

window.blurHash = () => {
    return {
        show: true,
        showBlurHash() {
            return this.show!== false;
        },
        hideBlurHash() {
            this.show= false;
        },
        render() {
            const canvas = this.$el.getElementsByTagName("canvas")[0];
            if (canvas.dataset.rendered) { return }
            const blurhash = canvas.dataset.blurhash
            const width = parseInt(canvas.getAttribute("width"), 10)
            const height = parseInt(canvas.getAttribute("height"), 10)
            const pixels = decode(blurhash, width, height);
            const ctx = canvas.getContext("2d");
            const imageData = ctx.createImageData(width, height);
            imageData.data.set(pixels);
            ctx.putImageData(imageData, 0, 0);
            canvas.dataset.rendered = true
        }
    }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    params: { _csrf_token: csrfToken },
    dom: {
        onBeforeElUpdated(from, to) {
            if (from.__x) { Alpine.clone(from.__x, to) }
        }
    }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


// PWA
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js', {scope: './'})
  .catch((error) => {
    // registration failed
    console.log('Registration failed with ' + error);
  });


  navigator.serviceWorker.ready.then((registration)=> {
    return registration.pushManager.getSubscription().then((subscription)=> {

      if (subscription) {
        return subscription;
      }

      return fetch('/web-push/vapid-public-key').then((response)=>{
        return response.text()
      }).then((vapidPublicKey)=>{
        // Chrome doesn’t accept the base64-encoded (string) vapidPublicKey yet urlBase64ToUint8Array() is defined in /tools.js
        const convertedVapidKey = urlBase64ToUint8Array(vapidPublicKey);

        return registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: convertedVapidKey
        });
      })
    });
  }).then(function(subscription) {
    fetch('/web-push/register', {
      method: 'post',
      headers: {
        'Content-type': 'application/json'
      },
      body: JSON.stringify({
        subscription: subscription
      }),
    });
  });
}
