import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { FeldsparRecovery } from "./feldspar_recovery";
import { FeldsparApp } from "./feldspar_app";

const SCOPE = "participant-1:assignment-2:task-3";
const LOST_ATTEMPT = "00000000-0000-4000-8000-000000000001";
const LATER_ATTEMPT = "00000000-0000-4000-8000-000000000002";
const markerKey = (scope, attemptId) =>
  `feldspar:attempt:${encodeURIComponent(scope)}:${attemptId}`;

// Model browser-owned locks: concurrent pages cannot acquire a held attempt,
// and releasing a page releases its lock without deleting localStorage.
class BrowserLocks {
  held = new Set();

  async request(name, _options, callback) {
    await Promise.resolve();
    if (this.held.has(name)) return callback(null);
    this.held.add(name);
    try {
      return await callback({ name });
    } finally {
      this.held.delete(name);
    }
  }
}

function deferred() {
  let resolve;
  const promise = new Promise((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

describe("Feldspar tab recovery", () => {
  let recoveries;
  let apps;
  let channels;

  beforeEach(() => {
    window.localStorage.clear();
    recoveries = [];
    apps = [];
    channels = [];
    vi.stubGlobal("navigator", { locks: new BrowserLocks() });
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({ ok: true, status: 200, json: async () => ({}) }))
    );
    vi.stubGlobal(
      "MessageChannel",
      class {
        constructor() {
          this.port1 = {
            postMessage: vi.fn(),
            close: vi.fn(),
            onmessage: null,
          };
          this.port2 = { close: vi.fn() };
          channels.push(this);
        }
      }
    );
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(console, "warn").mockImplementation(() => {});
  });

  afterEach(() => {
    apps.forEach((app) => {
      if (!app.isDestroyed) app.destroyed();
    });
    recoveries.forEach((hook) => {
      if (!hook.disposed) hook.destroyed();
    });
    document.body.innerHTML = "";
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
    window.localStorage.clear();
  });

  function seed(scope = SCOPE, attemptId = LOST_ATTEMPT) {
    const key = markerKey(scope, attemptId);
    window.localStorage.setItem(
      key,
      JSON.stringify({ attempt_id: attemptId, started_at: 1234 })
    );
    return key;
  }

  async function mount({ scope = SCOPE, onEntry = "check" } = {}) {
    const el = document.createElement("div");
    el.id = `recovery-${recoveries.length}`;
    el.setAttribute("phx-hook", "FeldsparRecovery");
    el.dataset.recoveryScope = scope;
    el.dataset.recoveryOnEntry = onEntry;
    el.dataset.modalId = `modal-${recoveries.length}`;
    document.body.append(el);
    const events = new Map();
    const hook = {
      ...FeldsparRecovery,
      el,
      events,
      pushEvent: vi.fn(async () => ({})),
      handleEvent: (name, callback) => {
        events.set(name, callback);
        return name;
      },
      removeHandleEvent: (name) => events.delete(name),
    };
    recoveries.push(hook);
    await hook.mounted();
    return hook;
  }

  async function start(hook) {
    await hook.events.get("feldspar:prepare")({ id: hook.el.id });
    return hook.pushEvent.mock.calls.findLast(([event]) => event === "start")[1]
      .attempt_id;
  }

  function closeModal(hook) {
    const button = document.createElement("button");
    button.setAttribute("phx-click", "close_modal");
    button.setAttribute("phx-value-item", hook.el.dataset.modalId);
    document.body.append(button);
    button.click();
    button.remove();
  }

  function mountApp(hook, attemptId, pushEvent = vi.fn(async () => ({}))) {
    const el = document.createElement("div");
    el.dataset.attemptId = attemptId;
    el.dataset.src = "about:blank";
    el.dataset.uploadContext = "{}";
    el.append(document.createElement("iframe"));
    hook.el.append(el);
    const app = { ...FeldsparApp, el, pushEvent };
    apps.push(app);
    app.mounted();
    return app;
  }

  it("reports an unfinished attempt on return without starting or uploading", async () => {
    const first = await mount();
    const attemptId = await start(first);
    const key = markerKey(SCOPE, attemptId);
    expect(JSON.parse(window.localStorage.getItem(key))).toEqual({
      attempt_id: attemptId,
      started_at: expect.any(Number),
    });
    first.destroyed();
    first.el.remove();

    const returned = await mount();
    expect(returned.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: true }],
    ]);
    expect(window.localStorage.getItem(key)).not.toBeNull();
    expect(fetch).not.toHaveBeenCalled();
    expect(returned.el.querySelector("iframe")).toBeNull();
  });

  it("rechecks recovery on reconnect before an explicit first start", async () => {
    const hook = await mount();
    hook.pushEvent.mockClear();
    hook.disconnected();
    await hook.reconnected();
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    expect(fetch).not.toHaveBeenCalled();
    const attemptId = await start(hook);
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toBeNull();
  });

  it("recovers its retained attempt on reconnect without restarting or retiring a sibling", async () => {
    const sibling = await mount();
    const siblingId = await start(sibling);
    const hook = await mount();
    const interruptedId = await start(hook);
    const interruptedKey = markerKey(SCOPE, interruptedId);
    hook.pushEvent.mockClear();
    hook.disconnected();
    await hook.reconnected();
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: true }],
    ]);
    expect(window.localStorage.getItem(interruptedKey)).not.toBeNull();
    expect(fetch).not.toHaveBeenCalled();
    const retryId = await start(hook);
    expect(retryId).not.toBe(interruptedId);
    expect(window.localStorage.getItem(interruptedKey)).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, siblingId))
    ).not.toBeNull();
    await navigator.locks.request(
      markerKey(SCOPE, siblingId),
      { ifAvailable: true },
      (lock) => expect(lock).toBeNull()
    );
  });

  it("retires only its own reconnected attempt when Web Locks are unavailable", async () => {
    vi.stubGlobal("navigator", {});
    const siblingKey = seed();
    const hook = await mount();
    const interruptedId = await start(hook);
    hook.disconnected();
    await hook.reconnected();
    hook.disconnected();
    await hook.reconnected();
    const retryId = await start(hook);
    expect(
      window.localStorage.getItem(markerKey(SCOPE, interruptedId))
    ).toBeNull();
    expect(window.localStorage.getItem(siblingKey)).not.toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });

  it("discards a recovery scan interrupted by disconnect", async () => {
    const key = seed();
    const hook = await mount();
    const lock = deferred();
    vi.spyOn(navigator.locks, "request").mockImplementationOnce(
      async (_name, _options, callback) => {
        await lock.promise;
        return callback({});
      }
    );
    hook.pushEvent.mockClear();
    const staleCheck = hook.checkRecovery();
    hook.disconnected();
    window.localStorage.removeItem(key);
    await hook.reconnected();
    lock.resolve();
    await staleCheck;
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
  });

  it("clears previous recovery once and preserves an explicit retry through patches and reconnect", async () => {
    const staleKey = seed();
    const hook = await mount({ onEntry: "clear_previous" });
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    expect(window.localStorage.getItem(staleKey)).toBeNull();

    const attemptId = await start(hook);
    const key = markerKey(SCOPE, attemptId);
    hook.el.dataset.recoveryOnEntry = "clear_previous";
    hook.updated?.();
    expect(window.localStorage.getItem(key)).not.toBeNull();
    hook.pushEvent.mockClear();
    hook.disconnected();
    await hook.reconnected();
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: true }],
    ]);
    expect(window.localStorage.getItem(key)).not.toBeNull();
    expect(fetch).not.toHaveBeenCalled();

    const retryId = await start(hook);
    expect(window.localStorage.getItem(key)).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });

  it("still starts explicitly when browser storage is denied", async () => {
    vi.spyOn(window, "localStorage", "get").mockImplementation(() => {
      throw new DOMException("Storage denied", "SecurityError");
    });
    const hook = await mount();
    expect(hook.pushEvent).toHaveBeenCalledWith("feldspar_recovery_checked", {
      unfinished: false,
    });
    const attemptId = await start(hook);
    expect(attemptId).toMatch(/^[0-9a-f-]{36}$/);
    expect(hook.pushEvent).toHaveBeenCalledWith("start", {
      attempt_id: attemptId,
    });
    closeModal(hook);
  });

  it("ignores malformed storage instead of presenting an unowned recovery", async () => {
    window.localStorage.setItem(markerKey(SCOPE, LOST_ATTEMPT), "{invalid");
    window.localStorage.setItem(
      markerKey(SCOPE, LATER_ATTEMPT),
      JSON.stringify({
        attempt_id: LOST_ATTEMPT,
        started_at: 1,
      })
    );
    const hook = await mount();
    expect(hook.pushEvent).toHaveBeenCalledWith("feldspar_recovery_checked", {
      unfinished: false,
    });
    const attemptId = await start(hook);
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toBeNull();
  });

  it("retires the recovery snapshot without clearing active siblings or later attempts", async () => {
    const sibling = await mount();
    const siblingId = await start(sibling);
    const lostKey = seed();
    const recovering = await mount();
    expect(recovering.pushEvent).toHaveBeenCalledWith(
      "feldspar_recovery_checked",
      { unfinished: true }
    );
    const laterKey = seed(SCOPE, LATER_ATTEMPT);

    const retryId = await start(recovering);
    expect(window.localStorage.getItem(lostKey)).toBeNull();
    expect(window.localStorage.getItem(laterKey)).not.toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, siblingId))
    ).not.toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();

    sibling.el.dispatchEvent(
      new CustomEvent("feldspar:terminal", {
        bubbles: true,
        detail: { attempt_id: siblingId },
      })
    );
    expect(window.localStorage.getItem(markerKey(SCOPE, siblingId))).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });

  it("does not offer recovery for an active sibling or another participant/task", async () => {
    const active = await mount();
    await start(active);
    seed("participant-2:assignment-2:task-3");
    seed("participant-1:assignment-2:task-4");
    const sameTask = await mount();
    expect(sameTask.pushEvent).toHaveBeenCalledWith(
      "feldspar_recovery_checked",
      { unfinished: false }
    );
  });

  it("preserves unknown sibling markers when Web Locks are unavailable", async () => {
    vi.stubGlobal("navigator", {});
    const oldKey = seed();
    const hook = await mount();
    expect(hook.pushEvent).toHaveBeenCalledWith("feldspar_recovery_checked", {
      unfinished: true,
    });
    const attemptId = await start(hook);
    await hook.cancelAttempt();
    expect(window.localStorage.getItem(oldKey)).not.toBeNull();
    expect(window.localStorage.getItem(markerKey(SCOPE, attemptId))).toBeNull();
  });

  it("clears only the initial orphan snapshot without starting or touching active siblings", async () => {
    const sibling = await mount();
    const siblingId = await start(sibling);
    const staleKey = seed();
    const otherKey = seed("participant-2:assignment-2:task-3");
    const scan = deferred();
    const request = navigator.locks.request.bind(navigator.locks);
    vi.spyOn(navigator.locks, "request").mockImplementationOnce(
      async (...args) => {
        await scan.promise;
        return request(...args);
      }
    );
    const mounting = mount({ onEntry: "clear_previous" });
    const laterKey = seed(SCOPE, LATER_ATTEMPT);
    scan.resolve();
    const hook = await mounting;
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    expect(window.localStorage.getItem(staleKey)).toBeNull();
    expect(window.localStorage.getItem(otherKey)).not.toBeNull();
    expect(window.localStorage.getItem(laterKey)).not.toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, siblingId))
    ).not.toBeNull();
    expect(fetch).not.toHaveBeenCalled();
  });

  it("suppresses unknown initial ownership without deleting it or hiding a later interrupted retry", async () => {
    vi.stubGlobal("navigator", {});
    const unknownKey = seed();
    const hook = await mount({ onEntry: "clear_previous" });
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    hook.disconnected();
    await hook.reconnected();
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    expect(window.localStorage.getItem(unknownKey)).not.toBeNull();

    const attemptId = await start(hook);
    hook.pushEvent.mockClear();
    hook.disconnected();
    await hook.reconnected();
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: true }],
    ]);
    const retryId = await start(hook);
    expect(window.localStorage.getItem(unknownKey)).not.toBeNull();
    expect(window.localStorage.getItem(markerKey(SCOPE, attemptId))).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });

  it("does not let a disconnected entry scan retire markers or consume its instruction", async () => {
    const key = seed();
    const scan = deferred();
    const request = navigator.locks.request.bind(navigator.locks);
    vi.spyOn(navigator.locks, "request").mockImplementationOnce(
      async (...args) => {
        await scan.promise;
        return request(...args);
      }
    );
    const mounting = mount({ onEntry: "clear_previous" });
    const hook = recoveries.at(-1);
    hook.disconnected();
    scan.resolve();
    await mounting;
    expect(hook.pushEvent).not.toHaveBeenCalled();
    expect(window.localStorage.getItem(key)).not.toBeNull();

    await hook.reconnected();
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    expect(window.localStorage.getItem(key)).toBeNull();
  });

  it("treats only the matching modal close as explicit cancellation", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const key = markerKey(SCOPE, attemptId);
    const button = document.createElement("button");
    button.setAttribute("phx-click", "close_modal");
    button.setAttribute("phx-value-item", "another-modal");
    const icon = document.createElement("span");
    button.append(icon);
    document.body.append(button);
    icon.click();
    expect(window.localStorage.getItem(key)).not.toBeNull();
    button.setAttribute("phx-value-item", hook.el.dataset.modalId);
    icon.click();
    expect(window.localStorage.getItem(key)).toBeNull();
  });

  it("cancels only the recovered snapshot, not an unfinished attempt discovered later", async () => {
    const lostKey = seed();
    const hook = await mount();
    const laterKey = seed(SCOPE, LATER_ATTEMPT);
    await hook.cancelAttempt();
    expect(window.localStorage.getItem(lostKey)).toBeNull();
    expect(window.localStorage.getItem(laterKey)).not.toBeNull();
  });

  it("keeps the marker until pending donations settle and the exit is acknowledged", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const key = markerKey(SCOPE, attemptId);
    const ack = deferred();
    const app = mountApp(
      hook,
      attemptId,
      vi.fn(() => ack.promise)
    );
    app.donations.add();
    const exiting = app.waitForDonationsAndExit({
      __type__: "CommandSystemExit",
      code: 0,
    });
    expect(app.pushEvent).not.toHaveBeenCalled();
    expect(window.localStorage.getItem(key)).not.toBeNull();
    app.donations.done();
    await Promise.resolve();
    expect(app.pushEvent).toHaveBeenCalledWith("feldspar_event", {
      __type__: "CommandSystemExit",
      code: 0,
    });
    expect(window.localStorage.getItem(key)).not.toBeNull();
    ack.resolve({});
    await exiting;
    expect(window.localStorage.getItem(key)).toBeNull();
  });

  it("clears an acknowledged unsuccessful exit without offering crash recovery on return", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const key = markerKey(SCOPE, attemptId);
    const ack = deferred();
    const app = mountApp(
      hook,
      attemptId,
      vi.fn(() => ack.promise)
    );
    const exiting = app.waitForDonationsAndExit({
      __type__: "CommandSystemExit",
      code: 1,
      info: "Processing failed",
    });
    expect(window.localStorage.getItem(key)).not.toBeNull();
    ack.resolve({});
    await exiting;
    expect(window.localStorage.getItem(key)).toBeNull();
    app.destroyed();
    hook.destroyed();
    hook.el.remove();
    const returned = await mount();
    expect(returned.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
  });

  it("retains recovery when an unsuccessful exit cannot be acknowledged", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const app = mountApp(
      hook,
      attemptId,
      vi.fn(async () => {
        throw new Error("LiveView disconnected");
      })
    );
    await app.waitForDonationsAndExit({
      __type__: "CommandSystemExit",
      code: 1,
      info: "Processing failed",
    });
    app.destroyed();
    hook.destroyed();
    hook.el.remove();
    const returned = await mount();
    expect(returned.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: true }],
    ]);
  });

  it("retains recovery after successful upload if the tab disappears before exit", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const app = mountApp(hook, attemptId);
    await app.donate_via_api({
      key: "answer",
      json_string: '{"private":"donation"}',
    });
    expect(fetch).toHaveBeenCalledWith(
      "/api/feldspar/donate",
      expect.objectContaining({ method: "POST" })
    );
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toContain("private");
    app.destroyed();
    hook.destroyed();
    hook.el.remove();
    fetch.mockClear();
    const returned = await mount();
    expect(returned.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: true }],
    ]);
    expect(fetch).not.toHaveBeenCalled();
  });

  it("clears an acknowledged exit even when its diff already removed the hooks", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const ack = deferred();
    const app = mountApp(
      hook,
      attemptId,
      vi.fn(() => ack.promise)
    );
    const exiting = app.waitForDonationsAndExit({
      __type__: "CommandSystemExit",
      code: 0,
    });
    app.destroyed();
    hook.destroyed();
    hook.el.remove();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toBeNull();
    ack.resolve({});
    await exiting;
    expect(window.localStorage.getItem(markerKey(SCOPE, attemptId))).toBeNull();
  });

  it("does not let an older exit acknowledgment clear a retry", async () => {
    const hook = await mount();
    const oldId = await start(hook);
    const ack = deferred();
    const app = mountApp(
      hook,
      oldId,
      vi.fn(() => ack.promise)
    );
    const exiting = app.waitForDonationsAndExit({
      __type__: "CommandSystemExit",
      code: 0,
    });
    closeModal(hook);
    const retryId = await start(hook);
    ack.resolve({});
    await exiting;
    expect(window.localStorage.getItem(markerKey(SCOPE, oldId))).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });

  it("closes the channel and removes listeners without treating teardown as cancellation", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const app = mountApp(hook, attemptId);
    app.onAppLoaded();
    const channel = channels.at(-1);
    const iframe = app.getIframe();
    app.destroyed();
    hook.destroyed();
    window.dispatchEvent(
      new MessageEvent("message", {
        source: iframe.contentWindow,
        data: { action: "resize", height: 123 },
      })
    );
    closeModal(hook);
    expect(channel.port1.close).toHaveBeenCalledOnce();
    expect(channel.port2.close).toHaveBeenCalledOnce();
    expect(iframe.getAttribute("style")).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toBeNull();
  });
});
