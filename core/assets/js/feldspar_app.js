export const FeldsparApp = {
  mounted() {
    console.log("[FeldsparApp] Mounted");

    console.log(this.el.dataset);

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
    console.log("[FeldsparApp] Initializing iframe app");
    this.channel = new MessageChannel();
    this.channel.port1.onmessage = (e) => {
      this.handleMessage(e);
    };

    let action = "live-init";
    let locale = this.el.dataset.locale;

    const iframe = this.getIframe();

    iframe.contentWindow.postMessage({ action, locale }, "*", [
      this.channel.port2,
    ]);

    const observer = new ResizeObserver(() => {
      const height = iframe.contentWindow.document.body.scrollHeight;
      iframe.setAttribute("style", `height:${height}px`);
    });

    observer.observe(iframe.contentWindow.document.body);
  },

  handleMessage(e) {
    this.pushEvent("feldspar_event", e.data);
  },
};
