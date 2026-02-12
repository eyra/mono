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

  async handleMessage(e) {
    const type = e.data.__type__;

    if (type === "CommandSystemDonate") {
      // handle large data donations via HTTP POST instead of WebSocket
      await this.donate_via_api(e.data);
    } else {
      // All other events (including CommandSystemExit) pass through to LiveView
      try {
        this.pushEvent("feldspar_event", e.data);
      } catch (error) {
        console.warn(
          "[Feldspar] Could not push event (LiveView disconnected):",
          type
        );
      }
    }
  },

  // Donate response contract (sent via MessageChannel to Feldspar app):
  // - DonateSuccess: { __type__: "DonateSuccess", key: string, status: number }
  // - DonateError: { __type__: "DonateError", key: string, status: number, error: string }
  //   Note: status=0 indicates a network error (offline, timeout, CORS, etc.)
  async donate_via_api(data) {
    const formData = new FormData();
    formData.append("key", data.key);
    formData.append("context", this.el.dataset.uploadContext || "{}");
    formData.append(
      "data",
      new Blob([data.json_string], { type: "application/json" }),
      "data.json"
    );

    let response;
    const dataSize = data.json_string ? data.json_string.length : 0;
    console.log("[Feldspar] Donate starting:", { key: data.key, dataSize });

    try {
      response = await fetch("/api/feldspar/donate", {
        method: "POST",
        body: formData,
      });
      console.log("[Feldspar] Donate fetch completed:", {
        key: data.key,
        status: response.status,
      });
    } catch (error) {
      // Network error (offline, timeout, etc.)
      console.error("[Feldspar] Donate network error:", error.message);
      this.sendDonateResponse({
        __type__: "DonateError",
        key: data.key,
        status: 0,
        error: `Network error: ${error.message}`,
      });
      return;
    }

    try {
      const result = await response.json();

      if (response.ok) {
        console.log("[Feldspar] Donate success:", {
          key: data.key,
          status: response.status,
        });
        this.sendDonateResponse({
          __type__: "DonateSuccess",
          key: data.key,
          status: response.status,
        });
      } else {
        console.error(
          "[Feldspar] Donate failed:",
          response.status,
          result.error
        );
        this.sendDonateResponse({
          __type__: "DonateError",
          key: data.key,
          status: response.status,
          error: result.error || "Unknown error",
        });
      }
    } catch (error) {
      // JSON parse error
      console.error("[Feldspar] Donate response parse error:", error.message);
      this.sendDonateResponse({
        __type__: "DonateError",
        key: data.key,
        status: response.status,
        error: "Invalid response from server",
      });
    }
  },

  sendDonateResponse(message) {
    if (this.channel && this.channel.port1) {
      this.channel.port1.postMessage(message);
    }
  },
};
