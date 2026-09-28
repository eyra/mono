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
    vi.spyOn(document, "visibilityState", "get").mockReturnValue("visible");
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
    vi.useRealTimers();
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

  async function mount({ scope = SCOPE, completed = false } = {}) {
    const el = document.createElement("div");
    el.id = `recovery-${recoveries.length}`;
    el.setAttribute("phx-hook", "FeldsparRecovery");
    el.dataset.recoveryScope = scope;
    el.dataset.completed = String(completed);
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
    app.onAppLoaded({ fromEvent: "app-loaded" });
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

  it("suppresses stale recovery for completed tasks and clears only their scope", async () => {
    const staleKey = seed();
    const otherKey = seed("participant-2:assignment-2:task-3");
    const hook = await mount({ completed: true });
    expect(hook.pushEvent.mock.calls).toEqual([
      ["feldspar_recovery_checked", { unfinished: false }],
    ]);
    await hook.events.get("feldspar:prepare")({ id: hook.el.id });
    expect(hook.pushEvent).not.toHaveBeenCalledWith("start", expect.anything());
    expect(window.localStorage.getItem(staleKey)).toBeNull();
    expect(window.localStorage.getItem(otherKey)).not.toBeNull();
  });

  it("clears a running marker when authoritative completion arrives", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    hook.el.dataset.completed = "true";
    hook.updated();
    expect(window.localStorage.getItem(markerKey(SCOPE, attemptId))).toBeNull();
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
    app.session.donations.add();
    const exiting = app.channel.port1.onmessage({
      data: { __type__: "CommandSystemExit" },
    });
    expect(app.pushEvent).not.toHaveBeenCalled();
    expect(window.localStorage.getItem(key)).not.toBeNull();
    app.session.donations.done();
    await Promise.resolve();
    expect(app.pushEvent).toHaveBeenCalledWith("feldspar_event", {
      __type__: "CommandSystemExit",
      attempt_id: attemptId,
    });
    expect(window.localStorage.getItem(key)).not.toBeNull();
    ack.resolve({});
    await exiting;
    expect(window.localStorage.getItem(key)).toBeNull();
  });

  it("retains recovery after successful upload if the tab disappears before exit", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const app = mountApp(hook, attemptId);
    await app.channel.port1.onmessage({
      data: {
        __type__: "CommandSystemDonate",
        key: "answer",
        json_string: '{"private":"donation"}',
      },
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
    const exiting = app.channel.port1.onmessage({
      data: { __type__: "CommandSystemExit" },
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
    const exiting = app.channel.port1.onmessage({
      data: { __type__: "CommandSystemExit" },
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

  it("closes replaced channels and removes listeners without treating teardown as cancellation", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    const app = mountApp(hook, attemptId);
    app.onAppLoaded({ fromEvent: "onload" });
    const firstChannel = channels.at(-1);
    app.onAppLoaded({ fromEvent: "app-loaded" });
    const lastChannel = channels.at(-1);
    expect(firstChannel.port1.close).toHaveBeenCalledOnce();
    expect(firstChannel.port2.close).toHaveBeenCalledOnce();
    const iframe = app.getIframe();
    app.destroyed();
    hook.destroyed();
    iframe.dispatchEvent(new Event("load"));
    window.dispatchEvent(
      new MessageEvent("message", {
        source: iframe.contentWindow,
        data: { action: "resize", height: 123 },
      })
    );
    closeModal(hook);
    expect(lastChannel.port1.close).toHaveBeenCalledOnce();
    expect(lastChannel.port2.close).toHaveBeenCalledOnce();
    expect(iframe.getAttribute("style")).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toBeNull();
  });

  async function enableMonitor(app) {
    await app.channel.port1.onmessage({
      data: {
        __type__: "LivenessReady",
        attempt_id: app.attemptId,
      },
    });
    await app.channel.port1.onmessage({
      data: { __type__: "CommandSystemEvent", name: "initialized" },
    });
  }

  it("keeps a timed-out marker and releases its lock for an explicit fresh retry", async () => {
    vi.useFakeTimers();
    vi.spyOn(performance, "now").mockImplementation(() => Date.now());
    const hook = await mount();
    const oldId = await start(hook);
    const oldKey = markerKey(SCOPE, oldId);
    const marker = window.localStorage.getItem(oldKey);
    const app = mountApp(hook, oldId);
    await enableMonitor(app);
    const queued = app.channel.port1.onmessage;
    vi.advanceTimersByTime(30000);
    expect(hook.pushEvent).toHaveBeenCalledWith("feldspar_unresponsive", {
      attempt_id: oldId,
    });
    expect(window.localStorage.getItem(oldKey)).toBe(marker);
    await Promise.resolve();
    expect(navigator.locks.held.has(oldKey)).toBe(false);
    expect(
      hook.pushEvent.mock.calls.filter(([event]) => event === "start")
    ).toHaveLength(1);
    const laterKey = seed(SCOPE, LATER_ATTEMPT);
    const retryId = await start(hook);
    expect(retryId).not.toBe(oldId);
    expect(window.localStorage.getItem(oldKey)).toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
    expect(window.localStorage.getItem(laterKey)).not.toBeNull();
    await queued({ data: { __type__: "CommandSystemExit" } });
    hook.el.dispatchEvent(
      new CustomEvent("feldspar:unresponsive", {
        detail: { attempt_id: oldId },
      })
    );
    hook.el.dispatchEvent(
      new CustomEvent("feldspar:terminal", {
        detail: { attempt_id: oldId },
      })
    );
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
    expect(
      hook.pushEvent.mock.calls.filter(
        ([event]) => event === "feldspar_unresponsive"
      )
    ).toHaveLength(1);
  });

  it("retires its own timed-out snapshot without Web Locks, preserving unknown siblings", async () => {
    vi.stubGlobal("navigator", {});
    const siblingKey = seed();
    const hook = await mount();
    const oldId = await start(hook);
    hook.el.dispatchEvent(
      new CustomEvent("feldspar:unresponsive", {
        detail: { attempt_id: oldId },
      })
    );
    const retryId = await start(hook);
    expect(window.localStorage.getItem(markerKey(SCOPE, oldId))).toBeNull();
    expect(window.localStorage.getItem(siblingKey)).not.toBeNull();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });

  it("clears the timed-out snapshot only on explicit cancellation, not teardown", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    hook.el.dispatchEvent(
      new CustomEvent("feldspar:unresponsive", {
        detail: { attempt_id: attemptId },
      })
    );
    hook.destroyed();
    const key = markerKey(SCOPE, attemptId);
    expect(window.localStorage.getItem(key)).not.toBeNull();
    const returned = await mount();
    await returned.cancelAttempt();
    expect(window.localStorage.getItem(key)).toBeNull();
  });

  it("ignores wrong, duplicate and completed-task timeout notifications", async () => {
    const hook = await mount();
    const attemptId = await start(hook);
    hook.el.dispatchEvent(
      new CustomEvent("feldspar:unresponsive", {
        detail: { attempt_id: LOST_ATTEMPT },
      })
    );
    expect(hook.pushEvent).not.toHaveBeenCalledWith(
      "feldspar_unresponsive",
      expect.anything()
    );
    expect(
      window.localStorage.getItem(markerKey(SCOPE, attemptId))
    ).not.toBeNull();
    hook.el.dataset.completed = "true";
    hook.el.dispatchEvent(
      new CustomEvent("feldspar:unresponsive", {
        detail: { attempt_id: attemptId },
      })
    );
    await hook.prepareStart();
    expect(hook.pushEvent).not.toHaveBeenCalledWith(
      "feldspar_unresponsive",
      expect.anything()
    );
    expect(window.localStorage.getItem(markerKey(SCOPE, attemptId))).toBeNull();
    expect(
      hook.pushEvent.mock.calls.filter(([event]) => event === "start")
    ).toHaveLength(1);
  });

  it("fences an old pending exit during explicit retry without changing the replacement marker", async () => {
    const hook = await mount();
    const oldId = await start(hook);
    const app = mountApp(hook, oldId);
    const oldSession = app.session;
    oldSession.donations.add();
    const exiting = app.channel.port1.onmessage({
      data: { __type__: "CommandSystemExit" },
    });
    closeModal(hook);
    const retryId = await start(hook);
    const retryApp = mountApp(hook, retryId);
    oldSession.donations.done();
    await exiting;
    expect(app.pushEvent).not.toHaveBeenCalled();
    expect(retryApp.pushEvent).not.toHaveBeenCalled();
    expect(
      window.localStorage.getItem(markerKey(SCOPE, retryId))
    ).not.toBeNull();
  });
});
