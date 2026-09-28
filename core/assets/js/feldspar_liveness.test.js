import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { FeldsparLiveness } from "./feldspar_liveness";

const ATTEMPT = "00000000-0000-4000-8000-000000000001";
const OTHER_ATTEMPT = "00000000-0000-4000-8000-000000000002";
const ready = {
  __type__: "LivenessReady",
  attempt_id: ATTEMPT,
};

// Only the bridge responds here: no Python completion or application activity
// is needed to establish that a busy worker's containing iframe is still alive.
describe("Feldspar iframe liveness", () => {
  let monitor;
  let send;
  let unresponsive;
  let visibility;
  let clockOffset;

  beforeEach(() => {
    vi.useFakeTimers();
    clockOffset = 0;
    vi.spyOn(performance, "now").mockImplementation(
      () => Date.now() + clockOffset
    );
    visibility = vi
      .spyOn(document, "visibilityState", "get")
      .mockReturnValue("visible");
    send = vi.fn();
    unresponsive = vi.fn();
    monitor = new FeldsparLiveness(ATTEMPT, send, unresponsive);
  });

  afterEach(() => {
    monitor.stop();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  function start() {
    monitor.receive(ready);
    monitor.initialized();
  }

  function pong(overrides = {}) {
    return {
      ...send.mock.calls.at(-1)[0],
      __type__: "LivenessPong",
      ...overrides,
    };
  }

  it("leaves legacy and invalid capabilities entirely unmonitored", () => {
    monitor.initialized();
    monitor.receive({ ...ready, attempt_id: OTHER_ATTEMPT });
    monitor.receive({
      ...ready,
      __type__: "LivenessPong",
      sequence: 1,
    });
    vi.advanceTimersByTime(120000);
    expect(send).not.toHaveBeenCalled();
    expect(unresponsive).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it.each(["ready-first", "initialized-first"])(
    "waits for both signals in %s order",
    (order) => {
      if (order === "ready-first") monitor.receive(ready);
      else monitor.initialized();
      vi.advanceTimersByTime(60000);
      expect(send).not.toHaveBeenCalled();
      expect(unresponsive).not.toHaveBeenCalled();
      if (order === "ready-first") monitor.initialized();
      else monitor.receive(ready);
      expect(send.mock.calls).toEqual([
        [
          {
            __type__: "LivenessPing",
            attempt_id: ATTEMPT,
            sequence: 1,
          },
        ],
      ]);
    }
  );

  it("retransmits one outstanding probe and reports a 30-second silence only once", () => {
    start();
    vi.advanceTimersByTime(29999);
    expect(send.mock.calls.map(([message]) => message.sequence)).toEqual([
      1, 1, 1, 1, 1, 1,
    ]);
    expect(unresponsive).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(unresponsive).toHaveBeenCalledOnce();
    const sent = send.mock.calls.length;
    monitor.receive(pong());
    monitor.receive(ready);
    monitor.initialized();
    window.dispatchEvent(new Event("pageshow"));
    vi.advanceTimersByTime(60000);
    expect(unresponsive).toHaveBeenCalledOnce();
    expect(send).toHaveBeenCalledTimes(sent);
    expect(vi.getTimerCount()).toBe(0);
  });

  it("accepts a delayed matching reply and gives the next probe its full response window", () => {
    start();
    vi.advanceTimersByTime(29000);
    monitor.receive(pong());
    vi.advanceTimersByTime(1000);
    expect(send.mock.calls.at(-1)[0].sequence).toBe(2);
    vi.advanceTimersByTime(29999);
    expect(unresponsive).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it("rejects a response after its deadline even if the watchdog callback is queued behind it", () => {
    start();
    vi.advanceTimersByTime(26000);
    clockOffset += 4000;
    monitor.receive(pong());
    vi.advanceTimersByTime(4000);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it.each([
    { attempt_id: OTHER_ATTEMPT },
    { sequence: 0 },
    { sequence: -1 },
    { sequence: 1.5 },
    { sequence: "1" },
    { sequence: 2147483648 },
    { sequence: 2 },
  ])("does not treat an invalid correlation %j as a response", (invalid) => {
    start();
    vi.advanceTimersByTime(25000);
    monitor.receive(pong(invalid));
    vi.advanceTimersByTime(5000);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it("ignores duplicate replies and repeated readiness after a probe was acknowledged", () => {
    start();
    const firstPong = pong();
    monitor.receive(firstPong);
    vi.advanceTimersByTime(5000);
    expect(send.mock.calls.at(-1)[0].sequence).toBe(2);
    vi.advanceTimersByTime(25000);
    monitor.receive(firstPong);
    monitor.receive(ready);
    monitor.initialized();
    vi.advanceTimersByTime(5000);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it("keeps a busy Python worker healthy while its bridge continues replying", () => {
    start();
    for (let probe = 0; probe < 36; probe++) {
      monitor.receive(pong());
      vi.advanceTimersByTime(5000);
    }
    expect(send.mock.calls.at(-1)[0].sequence).toBe(37);
    expect(unresponsive).not.toHaveBeenCalled();
  });

  it("starts a fresh foreground window and rejects a pre-background reply", () => {
    start();
    const oldPong = pong();
    vi.advanceTimersByTime(25000);
    visibility.mockReturnValue("hidden");
    document.dispatchEvent(new Event("visibilitychange"));
    const sent = send.mock.calls.length;
    vi.advanceTimersByTime(300000);
    expect(send).toHaveBeenCalledTimes(sent);
    expect(unresponsive).not.toHaveBeenCalled();
    visibility.mockReturnValue("visible");
    document.dispatchEvent(new Event("visibilitychange"));
    expect(send.mock.calls.at(-1)[0].sequence).toBe(2);
    vi.advanceTimersByTime(25000);
    monitor.receive(oldPong);
    vi.advanceTimersByTime(5000);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it.each([
    ["pagehide", "pageshow", "window"],
    ["freeze", "resume", "document"],
  ])("resets the window across %s/%s", (pause, resume, target) => {
    start();
    vi.advanceTimersByTime(25000);
    const eventTarget = target === "window" ? window : document;
    eventTarget.dispatchEvent(new Event(pause));
    vi.advanceTimersByTime(60000);
    expect(unresponsive).not.toHaveBeenCalled();
    eventTarget.dispatchEvent(new Event(resume));
    vi.advanceTimersByTime(29999);
    expect(unresponsive).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it("treats a delayed parent timer as suspension, not evidence of an iframe failure", () => {
    start();
    const oldPong = pong();
    vi.advanceTimersByTime(25000);
    clockOffset += 60000;
    vi.advanceTimersByTime(5000);
    expect(unresponsive).not.toHaveBeenCalled();
    expect(send.mock.calls.at(-1)[0].sequence).toBe(2);
    vi.advanceTimersByTime(25000);
    monitor.receive(oldPong);
    vi.advanceTimersByTime(5000);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it("waits for foreground when the capability becomes ready in a hidden page", () => {
    visibility.mockReturnValue("hidden");
    start();
    vi.advanceTimersByTime(60000);
    expect(send).not.toHaveBeenCalled();
    visibility.mockReturnValue("visible");
    document.dispatchEvent(new Event("visibilitychange"));
    monitor.receive(pong());
    vi.advanceTimersByTime(5000);
    expect(send.mock.calls.at(-1)[0].sequence).toBe(2);
    expect(unresponsive).not.toHaveBeenCalled();
  });

  it("cannot restart after teardown, even when lifecycle events and queued replies arrive", () => {
    start();
    const latePong = pong();
    monitor.stop();
    monitor.receive(latePong);
    document.dispatchEvent(new Event("visibilitychange"));
    document.dispatchEvent(new Event("resume"));
    window.dispatchEvent(new Event("pageshow"));
    vi.advanceTimersByTime(60000);
    expect(send).toHaveBeenCalledOnce();
    expect(unresponsive).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });
});
