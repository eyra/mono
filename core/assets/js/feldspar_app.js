export const FeldsparApp = {
  mounted() {
    console.log("FeldsparApp MOUNTED");

    const iframe = this.getIframe();
    iframe.addEventListener("load", () => {
      this.onFrameLoaded();
    });
    iframe.setAttribute("src", this.el.dataset.src);
  },

  getIframe() {
    return this.el.querySelector("iframe");
  },

  onFrameLoaded() {
    console.log("Initializing iframe app");
    this.channel = new MessageChannel();
    this.channel.port1.onmessage = (e) => {
      this.handleMessage(e);
    };
    this.getIframe().contentWindow.postMessage("init", "*", [
      this.channel.port2,
    ]);
  },

  handleMessage(e) {
    this.pushEvent("feldspar_event", e.data);
  },
};
