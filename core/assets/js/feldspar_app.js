import { WaitGroup } from "./wait_group";
import { clearFeldsparAttempt } from "./feldspar_recovery";

// Send logs to server for AppSignal
function sendLog(level, message, context = {}) {
  fetch("/api/feldspar/log", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ level, message, context }),
  }).catch(() => {
    // Silently fail - don't let logging errors break the app
  });
}

export const FeldsparApp = {
  mounted() {
    this.donations = new WaitGroup();
    this.isDestroyed = false;
    this.recoveryRoot = this.el.closest('[phx-hook="FeldsparRecovery"]');
    this.recoveryScope = this.recoveryRoot?.dataset.recoveryScope;
    this.attemptId = this.el.dataset.attemptId;
    const iframe = this.getIframe();

    iframe.setAttribute("src", this.el.dataset.src);

    const onAppLoaded = this.onAppLoaded.bind(this);
    this.messageListener = function (event) {
      if (event.source !== iframe.contentWindow || !event.data) return;
      const { action } = event.data;
      if (action === "resize") {
        iframe.setAttribute("style", `height:${event.data.height}px`);
      }
      // Apps send app-loaded (since 2025-04-24) or, older ones, resize only once
      // they listen for live-init. The iframe load event can fire before that.
      if (action === "app-loaded" || action === "resize") {
        onAppLoaded();
      }
    };
    window.addEventListener("message", this.messageListener);
  },

  destroyed() {
    this.isDestroyed = true;
    window.removeEventListener("message", this.messageListener);
    this.closeChannel();
  },

  closeChannel() {
    if (this.channel) {
      this.channel.port1.onmessage = null;
      this.channel.port1.close();
      this.channel.port2.close();
      this.channel = null;
    }
  },

  getIframe() {
    return this.el.querySelector("iframe");
  },

  setupChannel() {
    // app-loaded and resize repeat; the first one creates the only channel.
    if (this.channel) {
      return false;
    }
    this.closeChannel();
    this.channel = new MessageChannel();
    this.channel.port1.onmessage = (e) => {
      this.handleMessage(e);
    };
    return true;
  },

  onAppLoaded() {
    if (this.isDestroyed) return;
    const iframe = this.getIframe();
    // The iframe may not be available yet due to modal timing.
    if (!iframe?.contentWindow) return;
    if (!this.setupChannel()) return;

    iframe.contentWindow.postMessage(
      { action: "live-init", locale: this.el.dataset.locale },
      "*",
      [this.channel.port2]
    );
  },

  async handleMessage(e) {
    const type = e.data.__type__;

    if (type === "CommandSystemLog") {
      // Handle log messages via HTTP POST to AppSignal
      this.handleLogCommand(e.data);
    } else if (type === "CommandSystemDonate") {
      // Handle large data donations via HTTP POST instead of WebSocket
      await this.donate_via_api(e.data);
    } else if (type === "CommandSystemExit") {
      // Wait for pending donations before exiting
      await this.waitForDonationsAndExit(e.data);
    } else {
      // All other events pass through to LiveView
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

  async waitForDonationsAndExit(data) {
    if (this.donations.count > 0) {
      console.log(
        `[Feldspar] Exit requested, waiting for ${this.donations.count} pending donations...`
      );
      sendLog(
        "info",
        `Exit waiting for ${this.donations.count} donations`,
        this.getLogContext()
      );

      await this.donations.wait();

      console.log("[Feldspar] All donations completed, proceeding with exit");
    }
    if (this.isDestroyed) return;

    try {
      await this.pushEvent("feldspar_event", data);
      clearFeldsparAttempt(this.recoveryScope, this.attemptId);
      this.recoveryRoot?.dispatchEvent(
        new CustomEvent("feldspar:terminal", {
          bubbles: true,
          detail: { attempt_id: this.attemptId },
        })
      );
      console.log("[Feldspar] Exit event sent");
      sendLog("info", "Exit event sent", this.getLogContext());
    } catch (error) {
      console.warn("[Feldspar] Could not push exit event:", error.message);
      sendLog(
        "error",
        `Could not push exit event: ${error.message}`,
        this.getLogContext()
      );
    }
  },

  handleLogCommand(data) {
    try {
      const payload = JSON.parse(data.json_string);
      const { level, message, ...context } = payload;
      // Merge uploadContext (assignment_id, task, participant, etc.) with log context
      sendLog(level, message, { ...this.getLogContext(), ...context });
    } catch (error) {
      console.warn(
        "[Feldspar] Invalid CommandSystemLog payload:",
        error.message
      );
    }
  },

  getLogContext() {
    try {
      return JSON.parse(this.el.dataset.uploadContext || "{}");
    } catch {
      return {};
    }
  },

  // Donate response contract (sent via MessageChannel to Feldspar app):
  // - DonateSuccess: { __type__: "DonateSuccess", key: string, status: number }
  // - DonateError: { __type__: "DonateError", key: string, status: number, error: string }
  //   Note: status=0 indicates a network error (offline, timeout, CORS, etc.)
  async donate_via_api(data) {
    this.donations.add();

    try {
      await this._performDonation(data);
    } finally {
      this.donations.done();
    }
  },

  async _performDonation(data) {
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
    const logContext = { ...this.getLogContext(), key: data.key, dataSize };

    console.log("[Feldspar] Donate starting:", { key: data.key, dataSize });
    sendLog("info", "Donate starting", logContext);

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
      sendLog("error", `Donate network error: ${error.message}`, logContext);
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
        sendLog("info", "Donate success", {
          ...logContext,
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
        sendLog("error", `Donate failed: ${result.error}`, {
          ...logContext,
          status: response.status,
        });
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
      sendLog("error", `Donate response parse error: ${error.message}`, {
        ...logContext,
        status: response.status,
      });
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
