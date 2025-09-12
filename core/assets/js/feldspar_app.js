export const FeldsparApp = {
  mounted() {
    console.log("[FeldsparApp] Mounted");

    console.log(this.el.dataset);

    const iframe = this.getIframe();

    // Legacy loading event from Feldspar apps. Newer apps (after 2025-04-30)
    // should use the app-loaded event. This should be kept for backwards
    // compatibility.
    iframe.addEventListener("load", () => {
      this.onAppLoaded({ fromEvent: "onload" });
    });

    iframe.setAttribute("src", this.el.dataset.src);

    const onAppLoaded = this.onAppLoaded.bind(this);
    window.addEventListener("message", function (event) {
      if (event.data.action === "resize") {
        console.log("[FeldsparApp] resize event:", event.data.height);
        iframe.setAttribute("style", `height:${event.data.height}px`);
      } else if (event.data.action === "app-loaded") {
        console.log("[FeldsparApp] app-loaded event");
        onAppLoaded({ fromEvent: "app-loaded" });
      }
    });
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
    console.log("[FeldsparApp] Initializing iframe app");
    console.log("[FeldsparApp] Loaded from event:", fromEvent);

    this.setupChannel({ fromEvent });
    let action = "live-init";
    let locale = this.el.dataset.locale;

    const iframe = this.getIframe();

    iframe.contentWindow.postMessage({ action, locale }, "*", [
      this.channel.port2,
    ]);
  },

  handleMessage(e) {
    this.pushEvent("feldspar_event", e.data);
  },
};
