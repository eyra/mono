import { beforeEach, describe, expect, it, vi } from "vitest";
import { KeyboardClick } from "./keyboard_click";

describe("KeyboardClick", () => {
  let card;
  let inner;
  let clicks;

  const press = (target, type, key) => {
    const event = new KeyboardEvent(type, {
      key,
      bubbles: true,
      cancelable: true,
    });
    target.dispatchEvent(event);
    return event;
  };

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="card" role="button" tabindex="0"><input id="inner" /></div>
    `;
    card = document.getElementById("card");
    inner = document.getElementById("inner");

    clicks = vi.fn();
    card.addEventListener("click", clicks);

    const hook = Object.create(KeyboardClick);
    hook.el = card;
    hook.mounted();
  });

  it("clicks on Enter", () => {
    const event = press(card, "keydown", "Enter");

    expect(clicks).toHaveBeenCalledTimes(1);
    expect(event.defaultPrevented).toBe(true);
  });

  it("clicks on Space when the key goes up", () => {
    press(card, "keydown", " ");
    expect(clicks).not.toHaveBeenCalled();

    press(card, "keyup", " ");
    expect(clicks).toHaveBeenCalledTimes(1);
  });

  it("keeps Space from scrolling the page", () => {
    expect(press(card, "keydown", " ").defaultPrevented).toBe(true);
  });

  it("ignores other keys", () => {
    press(card, "keydown", "a");
    press(card, "keyup", "a");

    expect(clicks).not.toHaveBeenCalled();
  });

  it("leaves keys pressed on a control inside it alone", () => {
    const enter = press(inner, "keydown", "Enter");
    press(inner, "keydown", " ");
    press(inner, "keyup", " ");

    expect(clicks).not.toHaveBeenCalled();
    expect(enter.defaultPrevented).toBe(false);
  });
});
