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

  it("submits the existing delete endpoint", () => {
    const submit = vi
      .spyOn(HTMLFormElement.prototype, "submit")
      .mockImplementation(() => {});

    installAuthSessionHandlers({ csrfToken: "csrf-token" });

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
