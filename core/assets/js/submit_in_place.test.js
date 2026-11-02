import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { SubmitInPlace } from "./submit_in_place";

describe("SubmitInPlace", () => {
  let hook;
  let reply;
  let windowListener;

  beforeEach(() => {
    document.body.innerHTML = `
      <form id="auth_form" phx-submit="submit">
        <input name="email" value="someone@example.com" />
        <div data-button-loading>
          <button type="submit">
            <div class="prism-btn prism-btn-loading" data-client-loading><span class="prism-btn-content">Continue</span></div>
          </button>
        </div>
      </form>
    `;

    hook = Object.create(SubmitInPlace);
    hook.el = document.getElementById("auth_form");
    hook.pushEvent = vi.fn((_event, _payload, onReply) => {
      reply = onReply;
    });
    hook.mounted();

    windowListener = vi.fn();
    window.addEventListener("submit", windowListener);
  });

  afterEach(() => {
    hook.destroyed();
    window.removeEventListener("submit", windowListener);
    document.body.innerHTML = "";
    reply = undefined;
  });

  const submit = () =>
    hook.el.dispatchEvent(
      new Event("submit", { bubbles: true, cancelable: true })
    );

  it("pushes the phx-submit event with the form values instead of LiveView's submit", () => {
    const notCancelled = submit();

    expect(notCancelled).toBe(false);
    expect(windowListener).not.toHaveBeenCalled();
    expect(hook.pushEvent).toHaveBeenCalledWith(
      "submit",
      { email: "someone@example.com" },
      expect.any(Function)
    );
  });

  it("keeps the focused field focused and editable", () => {
    const input = hook.el.querySelector("input");
    input.focus();

    submit();

    expect(document.activeElement).toBe(input);
    expect(input.readOnly).toBe(false);
  });

  it("sends one submit until the server replies", () => {
    submit();
    submit();
    expect(hook.pushEvent).toHaveBeenCalledTimes(1);

    reply();
    submit();
    expect(hook.pushEvent).toHaveBeenCalledTimes(2);
  });

  it("ends the loading feedback the reply did not re-render", () => {
    submit();
    reply();

    const face = hook.el.querySelector(".prism-btn");
    expect(face.classList).not.toContain("prism-btn-loading");
    expect(face.querySelector("span").classList).not.toContain(
      "prism-btn-content"
    );
  });
});
