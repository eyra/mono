export const FeldsparApp = {
  mounted() {
    const iframe = this.getIframe();
    if (iframe.contentDocument.readyState === "complete") {
      this.onFrameLoaded();
    }
    else {
      iframe.contentDocument.addEventListener("load", ()=>{ this.onFrameLoaded() });
    }
  },

  getIframe() {
    return this.el.querySelector("iframe");
  },

  onFrameLoaded() {
    console.log("Initializing iframe app")
    this.channel = new MessageChannel();
    this.channel.port1.onmessage = (e) => {
      this.handleMessage(e);
    };
    this.getIframe().contentWindow.postMessage("init", "*", [this.channel.port2]);
  },

  handleMessage(e) {
    this.pushEvent("app_event", e.data);
  }
};
