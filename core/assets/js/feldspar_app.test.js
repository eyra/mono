import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { FeldsparApp } from "./feldspar_app";

const ATTEMPT = "00000000-0000-4000-8000-000000000001";
const OTHER_ATTEMPT = "00000000-0000-4000-8000-000000000002";
const INITIALIZED = { __type__: "CommandSystemEvent", name: "initialized" };
const EXIT = { __type__: "CommandSystemExit" };
const DONATION = {
  __type__: "CommandSystemDonate",
  key: "answers",
  json_string: '{"answer":42}',
};
const response = () => ({ ok: true, status: 200, json: async () => ({}) });

function deferred() {
  let resolve;
  const promise = new Promise((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

describe("FeldsparApp channel lifecycle", () => {
  let apps;
  let channels;

  beforeEach(() => {
    apps = [];
    channels = [];
    vi.useFakeTimers();
    vi.spyOn(performance, "now").mockImplementation(() => Date.now());
    vi.spyOn(document, "visibilityState", "get").mockReturnValue("visible");
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => response())
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
    document.body.innerHTML = "";
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  function mount({ recovery = true, attemptId = ATTEMPT } = {}) {
    const root = document.createElement("div");
    if (recovery) {
      root.setAttribute("phx-hook", "FeldsparRecovery");
      root.dataset.recoveryScope = "participant:assignment:task";
    }
    const el = document.createElement("div");
    if (attemptId) el.dataset.attemptId = attemptId;
    el.dataset.src = "about:blank";
    el.dataset.locale = "en";
    el.dataset.uploadContext = '{"assignment_id":2}';
    const iframe = document.createElement("iframe");
    el.append(iframe);
    root.append(el);
    document.body.append(root);
    const unresponsive = vi.fn();
    root.addEventListener("feldspar:unresponsive", unresponsive);
    const app = { ...FeldsparApp, el, pushEvent: vi.fn(async () => ({})) };
    apps.push(app);
    app.mounted();
    const init = vi.spyOn(iframe.contentWindow, "postMessage");
    app.onAppLoaded({ fromEvent: "app-loaded" });
    return { app, root, iframe, init, unresponsive };
  }

  function deliver(app, data) {
    return app.channel.port1.onmessage({ data });
  }

  async function monitor(app) {
    await deliver(app, {
      __type__: "LivenessReady",
      attempt_id: app.attemptId,
    });
    await deliver(app, INITIALIZED);
  }

  it("negotiates only with a real recovery scope and UUID attempt", () => {
    const { app, init } = mount();
    expect(init).toHaveBeenCalledWith(
      {
        action: "live-init",
        locale: "en",
        liveness: { attempt_id: ATTEMPT },
      },
      "*",
      [app.channel.port2]
    );
    for (const options of [
      { recovery: false, attemptId: null },
      { recovery: false },
      { attemptId: null },
      { attemptId: "not-an-attempt" },
    ]) {
      const standalone = mount(options);
      expect(standalone.init.mock.calls[0][0]).toEqual({
        action: "live-init",
        locale: "en",
      });
    }
  });

  it("keeps no-Ready bundles working without probes or a recovery deadline", async () => {
    const { app, unresponsive } = mount();
    await deliver(app, INITIALIZED);
    vi.advanceTimersByTime(120000);
    expect(app.channel.port1.postMessage).not.toHaveBeenCalled();
    expect(unresponsive).not.toHaveBeenCalled();
    expect(app.pushEvent.mock.calls).toEqual([
      ["feldspar_event", { ...INITIALIZED, attempt_id: ATTEMPT }],
    ]);
    await deliver(app, EXIT);
    expect(app.pushEvent).toHaveBeenLastCalledWith("feldspar_event", {
      ...EXIT,
      attempt_id: ATTEMPT,
    });
  });

  it("uses hook-owned attempt correlation, including standalone payloads", async () => {
    const { app } = mount();
    await deliver(app, { ...INITIALIZED, attempt_id: OTHER_ATTEMPT });
    expect(app.pushEvent).toHaveBeenCalledWith("feldspar_event", {
      ...INITIALIZED,
      attempt_id: ATTEMPT,
    });
    const standalone = mount({ recovery: false, attemptId: null });
    await deliver(standalone.app, {
      ...INITIALIZED,
      attempt_id: OTHER_ATTEMPT,
    });
    expect(standalone.app.pushEvent).toHaveBeenCalledWith(
      "feldspar_event",
      INITIALIZED
    );
  });

  it("accepts window messages only from its iframe and consumes liveness only on its channel", async () => {
    const { app, iframe, unresponsive } = mount();
    const channel = app.channel;
    const stranger = document.createElement("iframe");
    document.body.append(stranger);
    for (const data of [
      { action: "app-loaded" },
      { action: "resize", height: 999 },
    ]) {
      window.dispatchEvent(
        new MessageEvent("message", { source: stranger.contentWindow, data })
      );
    }
    expect(app.channel).toBe(channel);
    expect(iframe.getAttribute("style")).toBeNull();
    window.dispatchEvent(
      new MessageEvent("message", {
        source: iframe.contentWindow,
        data: { action: "resize", height: 123 },
      })
    );
    expect(iframe.style.height).toBe("123px");
    window.dispatchEvent(
      new MessageEvent("message", {
        source: iframe.contentWindow,
        data: {
          __type__: "LivenessReady",
          attempt_id: ATTEMPT,
        },
      })
    );
    await deliver(app, INITIALIZED);
    await deliver(app, {
      __type__: "LivenessPong",
      attempt_id: ATTEMPT,
      sequence: 1,
    });
    await deliver(app, {
      __type__: "LivenessPing",
      attempt_id: ATTEMPT,
      sequence: 1,
    });
    vi.advanceTimersByTime(60000);
    expect(channel.port1.postMessage).not.toHaveBeenCalled();
    expect(unresponsive).not.toHaveBeenCalled();
    expect(app.pushEvent.mock.calls).toEqual([
      ["feldspar_event", { ...INITIALIZED, attempt_id: ATTEMPT }],
    ]);
  });

  it("stops monitoring immediately on exit but still finishes pending donations before exit", async () => {
    const upload = deferred();
    fetch.mockImplementation((url) =>
      url === "/api/feldspar/donate"
        ? upload.promise
        : Promise.resolve(response())
    );
    const { app, unresponsive } = mount();
    await monitor(app);
    const channel = app.channel;
    channel.port1.postMessage.mockClear();
    app.pushEvent.mockClear();
    const donating = deliver(app, DONATION);
    const exiting = deliver(app, { ...EXIT, attempt_id: OTHER_ATTEMPT });
    await deliver(app, EXIT);
    await deliver(app, INITIALIZED);
    vi.advanceTimersByTime(90000);
    expect(unresponsive).not.toHaveBeenCalled();
    expect(channel.port1.postMessage).not.toHaveBeenCalled();
    expect(app.pushEvent).not.toHaveBeenCalled();
    upload.resolve(response());
    await donating;
    await exiting;
    expect(channel.port1.postMessage.mock.calls).toEqual([
      [
        {
          __type__: "DonateSuccess",
          key: "answers",
          status: 200,
        },
      ],
    ]);
    expect(app.pushEvent.mock.calls).toEqual([
      ["feldspar_event", { ...EXIT, attempt_id: ATTEMPT }],
    ]);
  });

  it("fences a timed-out channel before notifying recovery and never retries its upload", async () => {
    const upload = deferred();
    fetch.mockImplementation((url) =>
      url === "/api/feldspar/donate"
        ? upload.promise
        : Promise.resolve(response())
    );
    const { app, root, iframe, unresponsive } = mount();
    await monitor(app);
    const oldChannel = app.channel;
    const queued = oldChannel.port1.onmessage;
    const donating = deliver(app, DONATION);
    root.addEventListener("feldspar:unresponsive", () => {
      queued({ data: EXIT });
      expect(app.channel).toBeNull();
    });
    vi.advanceTimersByTime(30000);
    expect(unresponsive).toHaveBeenCalledOnce();
    expect(unresponsive.mock.calls[0][0].detail).toEqual({
      attempt_id: ATTEMPT,
    });
    const sent = oldChannel.port1.postMessage.mock.calls.length;
    await queued({ data: DONATION });
    await queued({ data: INITIALIZED });
    upload.resolve(response());
    await donating;
    iframe.dispatchEvent(new Event("load"));
    window.dispatchEvent(
      new MessageEvent("message", {
        source: iframe.contentWindow,
        data: { action: "app-loaded" },
      })
    );
    vi.advanceTimersByTime(60000);
    expect(channels).toHaveLength(1);
    expect(oldChannel.port1.postMessage).toHaveBeenCalledTimes(sent);
    expect(
      fetch.mock.calls.filter(([url]) => url === "/api/feldspar/donate")
    ).toHaveLength(1);
    expect(app.pushEvent.mock.calls).toEqual([
      ["feldspar_event", { ...INITIALIZED, attempt_id: ATTEMPT }],
    ]);
    expect(unresponsive).toHaveBeenCalledOnce();
  });

  it("rejects queued callbacks and upload replies from a replaced channel", async () => {
    const upload = deferred();
    fetch.mockImplementation((url) =>
      url === "/api/feldspar/donate"
        ? upload.promise
        : Promise.resolve(response())
    );
    const { app, unresponsive } = mount();
    await monitor(app);
    const oldChannel = app.channel;
    const queued = oldChannel.port1.onmessage;
    const donating = deliver(app, DONATION);
    app.onAppLoaded({ fromEvent: "app-loaded" });
    const currentChannel = app.channel;
    await queued({ data: EXIT });
    await queued({ data: DONATION });
    await queued({
      data: {
        __type__: "LivenessReady",
        attempt_id: ATTEMPT,
      },
    });
    upload.resolve(response());
    await donating;
    await deliver(app, INITIALIZED);
    vi.advanceTimersByTime(60000);
    expect(currentChannel.port1.postMessage).not.toHaveBeenCalled();
    expect(oldChannel.port1.close).toHaveBeenCalledOnce();
    expect(oldChannel.port2.close).toHaveBeenCalledOnce();
    expect(
      fetch.mock.calls.filter(([url]) => url === "/api/feldspar/donate")
    ).toHaveLength(1);
    expect(app.pushEvent.mock.calls).toEqual([
      ["feldspar_event", { ...INITIALIZED, attempt_id: ATTEMPT }],
      ["feldspar_event", { ...INITIALIZED, attempt_id: ATTEMPT }],
    ]);
    expect(unresponsive).not.toHaveBeenCalled();
  });

  it.each(["cancel", "destroy"])(
    "fences pending upload/exit completion on %s",
    async (ending) => {
      const upload = deferred();
      fetch.mockImplementation((url) =>
        url === "/api/feldspar/donate"
          ? upload.promise
          : Promise.resolve(response())
      );
      const { app, root, iframe, unresponsive } = mount();
      await monitor(app);
      const channel = app.channel;
      const queued = channel.port1.onmessage;
      const donating = deliver(app, DONATION);
      const exiting = deliver(app, EXIT);
      if (ending === "cancel") {
        root.dispatchEvent(
          new CustomEvent("feldspar:cancel", {
            detail: { attempt_id: ATTEMPT },
          })
        );
      } else app.destroyed();
      const sent = channel.port1.postMessage.mock.calls.length;
      upload.resolve(response());
      await donating;
      await exiting;
      await queued({ data: EXIT });
      iframe.dispatchEvent(new Event("load"));
      document.dispatchEvent(new Event("resume"));
      window.dispatchEvent(new Event("pageshow"));
      vi.advanceTimersByTime(60000);
      expect(channel.port1.postMessage).toHaveBeenCalledTimes(sent);
      expect(channels).toHaveLength(1);
      expect(app.pushEvent.mock.calls).toEqual([
        ["feldspar_event", { ...INITIALIZED, attempt_id: ATTEMPT }],
      ]);
      expect(unresponsive).not.toHaveBeenCalled();
    }
  );

  it("keeps log payloads out of application events and ignores malformed logs", async () => {
    const { app } = mount();
    await deliver(app, {
      __type__: "CommandSystemLog",
      json_string: "invalid json",
    });
    expect(fetch).not.toHaveBeenCalled();
    await deliver(app, {
      __type__: "CommandSystemLog",
      json_string: JSON.stringify({
        level: "error",
        message: "worker error",
        task: 3,
      }),
    });
    expect(fetch).toHaveBeenCalledWith("/api/feldspar/log", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        level: "error",
        message: "worker error",
        context: { assignment_id: 2, task: 3 },
      }),
    });
    expect(app.pushEvent).not.toHaveBeenCalled();
  });
});
