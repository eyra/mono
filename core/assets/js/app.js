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

const setupBlurHashes = (root) => {
    const images = root.getElementsByTagName("img");
    Array.prototype.forEach.call(images, (img)=>{
        const blurhash = img.dataset.blurhash
        if (img.complete || img.dataset.hasBlurHash || blurhash === undefined) { return }
        img.addEventListener("load", ()=>{
          canvas.classList.add("transition", "duration-700", "opacity-0")
        })
        const width = parseInt(img.getAttribute("width"), 10)
        const height = parseInt(img.getAttribute("height"), 10)
        const pixels = decode(img.dataset.blurhash, width, height);
        const canvas = document.createElement("canvas");
        canvas.classList.add(...img.classList.values());
        canvas.dataset.phxSkip = true
        canvas.setAttribute("width", width)
        canvas.setAttribute("height", height)
        canvas.classList.add("z-10", "absolute")
        const ctx = canvas.getContext("2d");
        const imageData = ctx.createImageData(width, height);
        imageData.data.set(pixels);
        ctx.putImageData(imageData, 0, 0);
        img.insertAdjacentElement("beforebegin", canvas);
        img.dataset.hasBlurHash = true
    })
}


window.addEventListener("DOMContentLoaded", ()=>{
    setupBlurHashes(document.body)
})

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    params: { _csrf_token: csrfToken },
    dom: {
        onBeforeElUpdated(from, to) {
            if (from.__x) { Alpine.clone(from.__x, to) }
            setupBlurHashes(from, to)
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
