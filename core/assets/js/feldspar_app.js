import { WaitGroup } from "./wait_group";
import { clearFeldsparAttempt, isFeldsparAttemptId } from "./feldspar_recovery";
import { FeldsparLiveness } from "./feldspar_liveness";

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
    this.isDestroyed = false;
    this.isStopped = false;
    this.recoveryRoot = this.el.closest('[phx-hook="FeldsparRecovery"]');
    this.recoveryScope = this.recoveryRoot?.dataset.recoveryScope;
    this.attemptId = this.el.dataset.attemptId;
    this.cancelListener = (event) => {
      if (event.detail?.attempt_id !== this.attemptId) return;
      this.stopAttempt();
    };
    this.recoveryRoot?.addEventListener("feldspar:cancel", this.cancelListener);
    const iframe = this.getIframe();

    // Legacy loading event from Feldspar apps. Newer apps (after 2025-04-30)
    // should use the app-loaded event. This should be kept for backwards
    // compatibility.
    this.loadListener = () => {
      this.onAppLoaded({ fromEvent: "onload" });
    };
    iframe.addEventListener("load", this.loadListener);

    iframe.setAttribute("src", this.el.dataset.src);

    this.messageListener = (event) => {
      if (
        this.isStopped ||
        event.source !== iframe.contentWindow ||
        !event.data
      )
        return;
      if (event.data.action === "resize") {
        iframe.setAttribute("style", `height:${event.data.height}px`);
      } else if (event.data.action === "app-loaded") {
        this.onAppLoaded({ fromEvent: "app-loaded" });
      }
    };
    window.addEventListener("message", this.messageListener);
  },

  destroyed() {
    this.isDestroyed = true;
    this.removeListeners();
    this.closeChannel({ preserveExitAcknowledgment: true });
  },

  stopAttempt() {
    this.isStopped = true;
    this.removeListeners();
    this.closeChannel();
  },

  removeListeners() {
    this.getIframe()?.removeEventListener("load", this.loadListener);
    window.removeEventListener("message", this.messageListener);
    this.recoveryRoot?.removeEventListener(
      "feldspar:cancel",
      this.cancelListener
    );
  },

  closeChannel({ preserveExitAcknowledgment = false } = {}) {
    if (this.session) {
      this.session.active = false;
      if (!preserveExitAcknowledgment)
        this.session.allowExitAcknowledgment = false;
      this.session.monitor?.stop();
      this.session = null;
    }
    if (this.channel) {
      this.channel.port1.onmessage = null;
      this.channel.port1.close();
      this.channel.port2.close();
      this.channel = null;
    }
  },

  isCurrentSession(session) {
    return !this.isDestroyed && session?.active && this.session === session;
  },

  eventPayload(data) {
    const { attempt_id: _untrustedAttempt, ...payload } = data;
    if (this.attemptId) payload.attempt_id = this.attemptId;
    return payload;
  },

  getIframe() {
    return this.el.querySelector("iframe");
  },

  setupChannel({ fromEvent }) {
    // The legacy loading event could cause the channel to be set up twice.
    if (fromEvent === "onload" && this.channel) {
      return false;
    }
    this.closeChannel();
    const channel = new MessageChannel();
    const session = {
      channel,
      donations: new WaitGroup(),
      active: true,
      exited: false,
      allowExitAcknowledgment: true,
    };
    this.channel = channel;
    this.session = session;
    if (this.recoveryScope && isFeldsparAttemptId(this.attemptId)) {
      session.monitor = new FeldsparLiveness(
        this.attemptId,
        (message) => {
          if (this.isCurrentSession(session))
            channel.port1.postMessage(message);
        },
        () => {
          if (!this.isCurrentSession(session)) return;
          this.stopAttempt();
          this.recoveryRoot.dispatchEvent(
            new CustomEvent("feldspar:unresponsive", {
              bubbles: true,
              detail: { attempt_id: this.attemptId },
            })
          );
        }
      );
    }
    channel.port1.onmessage = (event) => this.handleMessage(event, session);
    return true;
  },

  onAppLoaded({ fromEvent }) {
    if (this.isDestroyed || this.isStopped || this.session?.exited) return;
    let action = "live-init";
    let locale = this.el.dataset.locale;

    const iframe = this.getIframe();

    // Only add safety check for app-loaded events (not onload)
    // The onload event is reliable, app-loaded can fail due to modal timing
    if (fromEvent === "app-loaded" && (!iframe || !iframe.contentWindow)) {
      return;
    }
    if (!this.setupChannel({ fromEvent })) return;

    const payload = { action, locale };
    if (this.session.monitor) payload.liveness = { attempt_id: this.attemptId };
    iframe.contentWindow.postMessage(payload, "*", [this.channel.port2]);
  },

  async handleMessage(event, session = this.session) {
    if (!this.isCurrentSession(session) || session.exited) return;
    const data = event.data;
    if (!data || typeof data !== "object") return;
    const type = data.__type__;

    if (typeof type === "string" && type.startsWith("Liveness")) {
      session.monitor?.receive(data);
    } else if (type === "CommandSystemLog") {
      // Handle log messages via HTTP POST to AppSignal.
      this.handleLogCommand(data);
    } else if (type === "CommandSystemDonate") {
      // Handle large data donations via HTTP POST instead of WebSocket.
      await this.donate_via_api(data, session);
    } else if (type === "CommandSystemExit") {
      // Exit is terminal for monitoring even while uploads are still pending.
      session.exited = true;
      session.monitor?.stop();
      await this.waitForDonationsAndExit(data, session);
    } else {
      if (type === "CommandSystemEvent" && data.name === "initialized")
        session.monitor?.initialized();
      try {
        this.pushEvent("feldspar_event", this.eventPayload(data));
      } catch (error) {
        console.warn(
          "[Feldspar] Could not push event (LiveView disconnected):",
          type
        );
      }
    }
  },

  async waitForDonationsAndExit(data, session) {
    if (session.donations.count > 0) {
      console.log(
        `[Feldspar] Exit requested, waiting for ${session.donations.count} pending donations...`
      );
      sendLog(
        "info",
        `Exit waiting for ${session.donations.count} donations`,
        this.getLogContext()
      );

      await session.donations.wait();

      console.log("[Feldspar] All donations completed, proceeding with exit");
    }
    if (!this.isCurrentSession(session)) return;

    try {
      await this.pushEvent("feldspar_event", this.eventPayload(data));
      // LiveView's exit diff may already have destroyed this hook. The captured
      // attempt can still be cleared, unless cancellation/replacement fenced it.
      if (!session.allowExitAcknowledgment) return;
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
  async donate_via_api(data, session) {
    session.donations.add();

    try {
      await this._performDonation(data, session);
    } finally {
      session.donations.done();
    }
  },

  async _performDonation(data, session) {
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
      this.sendDonateResponse(
        {
          __type__: "DonateError",
          key: data.key,
          status: 0,
          error: `Network error: ${error.message}`,
        },
        session
      );
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
        this.sendDonateResponse(
          {
            __type__: "DonateSuccess",
            key: data.key,
            status: response.status,
          },
          session
        );
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
        this.sendDonateResponse(
          {
            __type__: "DonateError",
            key: data.key,
            status: response.status,
            error: result.error || "Unknown error",
          },
          session
        );
      }
    } catch (error) {
      // JSON parse error
      console.error("[Feldspar] Donate response parse error:", error.message);
      sendLog("error", `Donate response parse error: ${error.message}`, {
        ...logContext,
        status: response.status,
      });
      this.sendDonateResponse(
        {
          __type__: "DonateError",
          key: data.key,
          status: response.status,
          error: "Invalid response from server",
        },
        session
      );
    }
  },

  sendDonateResponse(message, session) {
    if (this.isCurrentSession(session)) {
      session.channel.port1.postMessage(message);
    }
  },
};
