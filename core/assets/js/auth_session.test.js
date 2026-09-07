import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { installAuthSessionHandlers } from "./auth_session";

describe("installAuthSessionHandlers", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
    window.history.replaceState({}, "", "/");
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("clears the logout event and submits the existing delete endpoint", () => {
    const postMessage = vi.fn();
    const submit = vi
      .spyOn(HTMLFormElement.prototype, "submit")
      .mockImplementation(() => {});

    vi.stubGlobal("webkit", {
      messageHandlers: { Native: { postMessage } },
    });

    window.history.replaceState(
      {},
      "",
      "/user/auth/identify?session_event=logged_out"
    );

    installAuthSessionHandlers({ csrfToken: "csrf-token" });

    expect(postMessage).toHaveBeenCalledWith({ type: "logged_out" });
    expect(window.location.search).toBe("");

    window.dispatchEvent(
      new CustomEvent("phx:auth:signout", {
        detail: { url: "/user/session" },
      })
    );

    const form = document.querySelector("form");
    expect(new URL(form.action).pathname).toBe("/user/session");
    expect(form.method).toBe("post");
    expect(form.elements._method.value).toBe("delete");
    expect(form.elements._csrf_token.value).toBe("csrf-token");
    expect(submit).toHaveBeenCalledOnce();
  });
});
