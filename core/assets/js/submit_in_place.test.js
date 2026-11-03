import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { SubmitInPlace } from "./submit_in_place";

describe("SubmitInPlace", () => {
  let hook;
  let pushes;
  let windowListener;

  beforeEach(() => {
    document.body.innerHTML = `
      <form id="auth_form" phx-submit="submit">
        <input name="email" value="someone@example.com" />
        <div data-button-loading>
          <button type="submit">
            <div class="prism-button prism-button--primary prism-button--loading" data-client-loading><span class="prism-button__label">Continue</span><span class="prism-spinner prism-spinner--20" data-client-loading></span></div>
          </button>
        </div>
      </form>
    `;

    pushes = [];
    hook = Object.create(SubmitInPlace);
    hook.el = document.getElementById("auth_form");
    hook.pushEvent = vi.fn(
      () => new Promise((resolve, reject) => pushes.push({ resolve, reject }))
    );
    hook.mounted();

    windowListener = vi.fn();
    window.addEventListener("submit", windowListener);
  });

  afterEach(() => {
    hook.destroyed();
    window.removeEventListener("submit", windowListener);
    document.body.innerHTML = "";
  });

  const submit = () =>
    hook.el.dispatchEvent(
      new Event("submit", { bubbles: true, cancelable: true })
    );

  const reply = async () => {
    pushes.at(-1).resolve({});
    await vi.waitFor(() => expect(hook.pending).toBe(false));
  };

  const fail = async () => {
    pushes
      .at(-1)
      .reject(new Error("unable to push hook event. LiveView not connected"));
    await vi.waitFor(() => expect(hook.pending).toBe(false));
  };

  const loading = () =>
    hook.el
      .querySelector(".prism-button")
      .classList.contains("prism-button--loading");

  it("pushes the phx-submit event with the form values instead of LiveView's submit", () => {
    const notCancelled = submit();

    expect(notCancelled).toBe(false);
    expect(windowListener).not.toHaveBeenCalled();
    expect(hook.pushEvent).toHaveBeenCalledWith("submit", {
      email: "someone@example.com",
    });
  });

  it("keeps the focused field focused and editable", () => {
    const input = hook.el.querySelector("input");
    input.focus();

    submit();

    expect(document.activeElement).toBe(input);
    expect(input.readOnly).toBe(false);
  });

  it("sends one submit until the server replies", async () => {
    submit();
    submit();
    expect(hook.pushEvent).toHaveBeenCalledTimes(1);

    await reply();
    submit();
    expect(hook.pushEvent).toHaveBeenCalledTimes(2);
  });

  it("ends the loading feedback the reply did not re-render", async () => {
    submit();
    await reply();

    expect(loading()).toBe(false);
    expect(hook.el.querySelector(".prism-spinner")).toBeNull();
  });

  it("sends the next submit after a push that failed while disconnected", async () => {
    submit();
    await fail();

    expect(loading()).toBe(false);

    submit();
    expect(hook.pushEvent).toHaveBeenCalledTimes(2);
  });

  it("sends the next submit after a reconnect, even if the push never settled", () => {
    submit();
    hook.reconnected();

    expect(loading()).toBe(false);

    submit();
    expect(hook.pushEvent).toHaveBeenCalledTimes(2);
  });
});
