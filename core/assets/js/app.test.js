import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("phoenix_html", () => ({}));
vi.mock("phoenix", () => ({ Socket: class {} }));
vi.mock("phoenix_live_view", () => ({
  LiveSocket: class {
    connect() {}
  },
}));
vi.mock("blurhash", () => ({ decode: vi.fn() }));
vi.mock("./pdf_viewer", () => ({ PDFViewer: {} }));
vi.mock("./tools", () => ({ urlBase64ToUint8Array: vi.fn() }));
vi.mock("./apns", () => ({ registerAPNSDeviceToken: vi.fn() }));
vi.mock("./100vh-fix", () => ({}));
vi.mock("./viewport", () => ({ Viewport: { sendToServer: vi.fn() } }));
vi.mock("./side_panel", () => ({ SidePanel: {} }));
vi.mock("./toggle", () => ({ Toggle: {} }));
vi.mock("./cell", () => ({ Cell: {} }));
vi.mock("./live_content", () => ({ LiveContent: {}, LiveField: {} }));
vi.mock("./tabbed", () => ({
  Tab: {},
  TabBar: {},
  TabBarFit: {},
  TabContent: {},
  TabFooterItem: {},
}));
vi.mock("./clipboard", () => ({ Clipboard: {} }));
vi.mock("./feldspar_app", () => ({ FeldsparApp: {} }));
vi.mock("./auth_code_input", () => ({ AuthCodeInput: {} }));
vi.mock("./wysiwyg", () => ({ Wysiwyg: {} }));
vi.mock("./auto_submit", () => ({ AutoSubmit: {} }));
vi.mock("./reset_scroll", () => ({ ResetScroll: {} }));
vi.mock("./fullscreen_image", () => ({ FullscreenImage: {} }));
vi.mock("./blurhash", () => ({ Blurhash: {} }));
vi.mock("./user_state", () => ({ UserState: {}, getAllUserState: () => ({}) }));

describe("app entrypoint", () => {
  beforeEach(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="entrypoint-csrf-token">';
    document.body.innerHTML = "";
    window.history.replaceState({}, "", "/");
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.resetModules();
  });

  it("initializes auth-session logout submission", async () => {
    const submit = vi
      .spyOn(HTMLFormElement.prototype, "submit")
      .mockImplementation(() => {});

    await import("./app");

    window.dispatchEvent(
      new CustomEvent("phx:auth:signout", {
        detail: { url: "/user/session" },
      })
    );

    const form = document.querySelector("form");
    expect(new URL(form.action).pathname).toBe("/user/session");
    expect(form.method).toBe("post");
    expect(form.elements._method.value).toBe("delete");
    expect(form.elements._csrf_token.value).toBe("entrypoint-csrf-token");
    expect(submit).toHaveBeenCalledOnce();
  });
});
