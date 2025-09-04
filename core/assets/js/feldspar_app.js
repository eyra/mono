export const FeldsparApp = {
  mounted() {
    const iframe = this.el.querySelector("iframe");

    // Legacy loading event from Feldspar apps. Newer apps (after 2025-04-30)
    // should use the app-loaded event. This should be kept for backwards
    // compatibility.
    iframe.addEventListener("load", () => {
      this.onAppLoaded({ fromEvent: "onload" });
    });

    iframe.setAttribute("src", this.el.dataset.src);

    const onAppLoaded = this.onAppLoaded.bind(this);
    this.messageListener = function (event) {
      if (event.data.action === "resize") {
        iframe.setAttribute("style", `height:${event.data.height}px`);
      } else if (event.data.action === "app-loaded") {
        onAppLoaded({ fromEvent: "app-loaded" });
      }
    };
    window.addEventListener("message", this.messageListener);
  },

  getIframe() {
    return this.el.querySelector("iframe");
  },

  setupChannel({ fromEvent }) {
    // The legacy loading event could cause the channel to be set up twice.
    if (fromEvent === "onload" && this.channel) {
      return;
    }
    this.channel = new MessageChannel();
    this.channel.port1.onmessage = (e) => {
      this.handleMessage(e);
    };
  },

  onAppLoaded({ fromEvent }) {
    this.setupChannel({ fromEvent });
    let action = "live-init";
    let locale = this.el.dataset.locale;

    const iframe = this.getIframe();

    // Only add safety check for app-loaded events (not onload)
    // The onload event is reliable, app-loaded can fail due to modal timing
    if (fromEvent === "app-loaded" && (!iframe || !iframe.contentWindow)) {
      return;
    }

    iframe.contentWindow.postMessage({ action, locale }, "*", [
      this.channel.port2,
    ]);
  },

  handleMessage(e) {
    this.pushEvent("feldspar_event", e.data);
  },
};
