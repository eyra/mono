import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { FeldsparApp } from "./feldspar_app";
import { WaitGroup } from "./wait_group";

describe("FeldsparApp", () => {
  let mockFetch;

  beforeEach(() => {
    // Mock fetch globally
    mockFetch = vi.fn(() => Promise.resolve({ ok: true }));
    global.fetch = mockFetch;

    // Suppress console.warn for cleaner test output
    vi.spyOn(console, "warn").mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("startup notifications", () => {
    let mountedApps;

    beforeEach(() => {
      mountedApps = [];
      vi.spyOn(console, "log").mockImplementation(() => {});
      vi.stubGlobal(
        "MessageChannel",
        class {
          constructor() {
            this.port1 = { postMessage: vi.fn(), onmessage: null };
            this.port2 = {};
          }
        }
      );
    });

    afterEach(() => {
      mountedApps.forEach(({ app }) =>
        window.removeEventListener("message", app.messageListener)
      );
      document.body.innerHTML = "";
      vi.unstubAllGlobals();
    });

    function mount() {
      const el = document.createElement("div");
      el.dataset.src = "about:blank";
      el.dataset.locale = "en";
      el.dataset.uploadContext = "{}";
      const iframe = document.createElement("iframe");
      el.append(iframe);
      document.body.append(el);
      const app = { ...FeldsparApp, el, pushEvent: vi.fn() };
      app.mounted();
      const init = vi.spyOn(iframe.contentWindow, "postMessage");
      const mounted = { app, iframe, init };
      mountedApps.push(mounted);
      return mounted;
    }

    function notify(iframe, event) {
      if (event === "load") {
        iframe.dispatchEvent(new Event("load"));
      } else {
        window.dispatchEvent(
          new MessageEvent("message", {
            source: iframe.contentWindow,
            data: { action: "app-loaded" },
          })
        );
      }
    }

    it.each([
      ["load", "app-loaded"],
      ["app-loaded", "load"],
    ])("initializes once for %s followed by %s", (first, second) => {
      const { app, iframe, init } = mount();
      notify(iframe, first);
      const channel = app.channel;
      notify(iframe, second);
      expect(init.mock.calls).toEqual([
        [{ action: "live-init", locale: "en" }, "*", [channel.port2]],
      ]);
      expect(app.channel).toBe(channel);
    });

    it.each(["load", "app-loaded"])(
      "initializes when %s is the only startup signal",
      (event) => {
        const { app, iframe, init } = mount();
        notify(iframe, event);
        expect(init.mock.calls).toEqual([
          [{ action: "live-init", locale: "en" }, "*", [app.channel.port2]],
        ]);
      }
    );

    it("keeps the original channel and pending donation through repeated startup signals", async () => {
      let finishUpload;
      const upload = new Promise((resolve) => {
        finishUpload = resolve;
      });
      mockFetch.mockImplementation((url) =>
        url === "/api/feldspar/donate" ? upload : Promise.resolve({ ok: true })
      );
      const { app, iframe, init } = mount();
      notify(iframe, "load");
      const channel = app.channel;
      const donating = app.handleMessage({
        data: {
          __type__: "CommandSystemDonate",
          key: "answers",
          json_string: '{"answer":42}',
        },
      });
      for (const event of ["app-loaded", "load", "app-loaded", "load"]) {
        notify(iframe, event);
      }
      const exit = { __type__: "CommandSystemExit", code: 0 };
      const exiting = app.handleMessage({ data: exit });
      expect(app.pushEvent).not.toHaveBeenCalled();
      finishUpload({ ok: true, status: 200, json: async () => ({}) });
      await donating;
      await exiting;
      expect(init).toHaveBeenCalledOnce();
      expect(app.channel).toBe(channel);
      expect(channel.port1.postMessage.mock.calls).toEqual([
        [{ __type__: "DonateSuccess", key: "answers", status: 200 }],
      ]);
      expect(app.pushEvent.mock.calls).toEqual([["feldspar_event", exit]]);
      expect(
        mockFetch.mock.calls.filter(([url]) => url === "/api/feldspar/donate")
      ).toHaveLength(1);
    });

    it("initializes a fresh retry iframe with its own channel", () => {
      const first = mount();
      notify(first.iframe, "load");
      first.app.el.remove();
      const retry = mount();
      notify(retry.iframe, "app-loaded");
      notify(retry.iframe, "load");
      expect(first.init).toHaveBeenCalledOnce();
      expect(retry.init.mock.calls).toEqual([
        [{ action: "live-init", locale: "en" }, "*", [retry.app.channel.port2]],
      ]);
      expect(retry.app.channel).not.toBe(first.app.channel);
    });

    it("does not reserve initialization before the iframe is available", () => {
      const el = document.createElement("div");
      el.dataset.locale = "en";
      document.body.append(el);
      const app = { ...FeldsparApp, el };
      app.onAppLoaded({ fromEvent: "app-loaded" });
      const iframe = document.createElement("iframe");
      el.append(iframe);
      const init = vi.spyOn(iframe.contentWindow, "postMessage");
      app.onAppLoaded({ fromEvent: "app-loaded" });
      expect(init.mock.calls).toEqual([
        [{ action: "live-init", locale: "en" }, "*", [app.channel.port2]],
      ]);
    });
  });

  describe("handleLogCommand", () => {
    it("sends log to /api/feldspar/log endpoint", () => {
      const data = {
        __type__: "CommandSystemLog",
        json_string: JSON.stringify({
          level: "info",
          message: "Test message",
        }),
      };

      FeldsparApp.handleLogCommand(data);

      expect(mockFetch).toHaveBeenCalledWith("/api/feldspar/log", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          level: "info",
          message: "Test message",
          context: {},
        }),
      });
    });

    it("includes context from payload", () => {
      const data = {
        __type__: "CommandSystemLog",
        json_string: JSON.stringify({
          level: "error",
          message: "Error occurred",
          source: "mock_app",
          userId: 123,
        }),
      };

      FeldsparApp.handleLogCommand(data);

      expect(mockFetch).toHaveBeenCalledWith("/api/feldspar/log", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          level: "error",
          message: "Error occurred",
          context: { source: "mock_app", userId: 123 },
        }),
      });
    });

    it("handles all log levels", () => {
      const levels = ["debug", "info", "warn", "error"];

      levels.forEach((level) => {
        mockFetch.mockClear();

        const data = {
          __type__: "CommandSystemLog",
          json_string: JSON.stringify({ level, message: `${level} message` }),
        };

        FeldsparApp.handleLogCommand(data);

        expect(mockFetch).toHaveBeenCalledTimes(1);
        const body = JSON.parse(mockFetch.mock.calls[0][1].body);
        expect(body.level).toBe(level);
      });
    });

    it("handles invalid JSON gracefully", () => {
      const data = {
        __type__: "CommandSystemLog",
        json_string: "not valid json",
      };

      // Should not throw
      expect(() => FeldsparApp.handleLogCommand(data)).not.toThrow();

      // Should not call fetch
      expect(mockFetch).not.toHaveBeenCalled();

      // Should warn
      expect(console.warn).toHaveBeenCalledWith(
        "[Feldspar] Invalid CommandSystemLog payload:",
        expect.any(String)
      );
    });
  });

  describe("handleMessage", () => {
    let mockPushEvent;

    beforeEach(() => {
      mockPushEvent = vi.fn();
      FeldsparApp.pushEvent = mockPushEvent;
    });

    it("routes CommandSystemLog to handleLogCommand", async () => {
      const spy = vi.spyOn(FeldsparApp, "handleLogCommand");

      const event = {
        data: {
          __type__: "CommandSystemLog",
          json_string: JSON.stringify({ level: "info", message: "test" }),
        },
      };

      await FeldsparApp.handleMessage(event);

      expect(spy).toHaveBeenCalledWith(event.data);
      expect(mockPushEvent).not.toHaveBeenCalled();
    });

    it("routes non-monitor messages to pushEvent", async () => {
      const event = {
        data: {
          __type__: "SomeOtherEvent",
          payload: "data",
        },
      };

      await FeldsparApp.handleMessage(event);

      expect(mockPushEvent).toHaveBeenCalledWith("feldspar_event", event.data);
    });

    it("routes CommandSystemDonate to donate_via_api", async () => {
      const spy = vi
        .spyOn(FeldsparApp, "donate_via_api")
        .mockResolvedValue(undefined);

      const event = {
        data: {
          __type__: "CommandSystemDonate",
          key: "test-key",
          json_string: "{}",
        },
      };

      await FeldsparApp.handleMessage(event);

      expect(spy).toHaveBeenCalledWith(event.data);
      expect(mockPushEvent).not.toHaveBeenCalled();
    });

    it("routes CommandSystemExit to waitForDonationsAndExit", async () => {
      const spy = vi
        .spyOn(FeldsparApp, "waitForDonationsAndExit")
        .mockResolvedValue(undefined);

      const event = {
        data: {
          __type__: "CommandSystemExit",
        },
      };

      await FeldsparApp.handleMessage(event);

      expect(spy).toHaveBeenCalledWith(event.data);
      expect(mockPushEvent).not.toHaveBeenCalled();
    });
  });

  describe("waitForDonationsAndExit", () => {
    let mockPushEvent;

    beforeEach(() => {
      mockPushEvent = vi.fn();
      FeldsparApp.pushEvent = mockPushEvent;
      FeldsparApp.donations = new WaitGroup();
      FeldsparApp.el = { dataset: { uploadContext: "{}" } };
    });

    it("pushes exit event immediately when no pending donations", async () => {
      const data = { __type__: "CommandSystemExit" };

      await FeldsparApp.waitForDonationsAndExit(data);

      expect(mockPushEvent).toHaveBeenCalledWith("feldspar_event", data);
    });

    it("waits for pending donations before pushing exit event", async () => {
      const data = { __type__: "CommandSystemExit" };
      const order = [];

      FeldsparApp.donations.add();

      const exitPromise = FeldsparApp.waitForDonationsAndExit(data).then(() =>
        order.push("exit")
      );

      // Exit should not have been called yet
      expect(mockPushEvent).not.toHaveBeenCalled();

      // Simulate donation completing
      setTimeout(() => {
        order.push("donation_done");
        FeldsparApp.donations.done();
      }, 10);

      await exitPromise;

      expect(order).toEqual(["donation_done", "exit"]);
      expect(mockPushEvent).toHaveBeenCalledWith("feldspar_event", data);
    });
  });
});
