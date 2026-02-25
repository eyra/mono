import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { FeldsparApp } from "./feldspar_app";

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
  });
});
