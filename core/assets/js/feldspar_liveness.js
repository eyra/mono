const PROBE_INTERVAL = 5000;
const RESPONSE_WINDOW = 30000;
const SCHEDULER_GAP = 10000;
const MAX_SEQUENCE = 2147483647;

// This measures the iframe bridge, not the health of its Python worker.
export class FeldsparLiveness {
  constructor(attemptId, send, onUnresponsive) {
    this.attemptId = attemptId;
    this.send = send;
    this.onUnresponsive = onUnresponsive;
    this.sequence = 0;
    this.pendingSequence = null;
    this.ready = false;
    this.hasInitialized = false;
    this.active = false;
    this.stopped = false;
    this.timer = null;
    this.onVisibility = () => {
      if (document.visibilityState === "hidden") this.suspend();
      else this.resume();
    };
    this.onSuspend = () => this.suspend();
    this.onResume = () => this.resume();
  }

  receive(data) {
    if (this.stopped || data.attempt_id !== this.attemptId) return;

    if (data.__type__ === "LivenessReady") {
      this.ready = true;
      this.start();
    } else if (
      data.__type__ === "LivenessPong" &&
      this.active &&
      !this.suspended &&
      document.visibilityState !== "hidden" &&
      Number.isInteger(data.sequence) &&
      data.sequence > 0 &&
      data.sequence <= MAX_SEQUENCE &&
      data.sequence === this.pendingSequence
    ) {
      const now = performance.now();
      if (now - this.lastTick > SCHEDULER_GAP) {
        this.resume();
        return;
      }
      if (now - this.pendingSince >= RESPONSE_WINDOW) return;
      this.pendingSequence = null;
      this.pendingSince = null;
    }
  }

  initialized() {
    this.hasInitialized = true;
    this.start();
  }

  start() {
    if (this.stopped || this.active || !this.ready || !this.hasInitialized)
      return;
    this.active = true;
    document.addEventListener("visibilitychange", this.onVisibility);
    document.addEventListener("freeze", this.onSuspend);
    document.addEventListener("resume", this.onResume);
    window.addEventListener("pagehide", this.onSuspend);
    window.addEventListener("pageshow", this.onResume);
    this.resume();
  }

  suspend() {
    this.suspended = true;
    clearTimeout(this.timer);
    this.timer = null;
    this.pendingSequence = null;
  }

  resume() {
    if (this.stopped || !this.active) return;
    this.suspend();
    if (document.visibilityState === "hidden") return;
    this.suspended = false;
    this.lastTick = performance.now();
    this.probe();
  }

  probe() {
    if (this.pendingSequence === null) {
      this.sequence = this.sequence === MAX_SEQUENCE ? 1 : this.sequence + 1;
      this.pendingSequence = this.sequence;
      this.pendingSince = performance.now();
    }
    this.send({
      __type__: "LivenessPing",
      attempt_id: this.attemptId,
      sequence: this.pendingSequence,
    });
    this.timer = setTimeout(() => this.tick(), PROBE_INTERVAL);
  }

  tick() {
    if (this.stopped || this.suspended) return;
    if (document.visibilityState === "hidden") {
      this.suspend();
      return;
    }
    const now = performance.now();
    if (now - this.lastTick > SCHEDULER_GAP) {
      this.resume();
      return;
    }
    this.lastTick = now;
    if (
      this.pendingSequence !== null &&
      now - this.pendingSince >= RESPONSE_WINDOW
    ) {
      this.stop();
      this.onUnresponsive();
      return;
    }
    this.probe();
  }

  stop() {
    this.stopped = true;
    this.suspend();
    document.removeEventListener("visibilitychange", this.onVisibility);
    document.removeEventListener("freeze", this.onSuspend);
    document.removeEventListener("resume", this.onResume);
    window.removeEventListener("pagehide", this.onSuspend);
    window.removeEventListener("pageshow", this.onResume);
  }
}
