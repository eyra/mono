import { afterEach, describe, expect, it } from "vitest";
import { installButtonLoading } from "./button_loading";

describe("installButtonLoading", () => {
  let uninstall;

  afterEach(() => {
    uninstall?.();
    uninstall = undefined;
    document.body.innerHTML = "";
  });

  it("shows loading feedback in the click event before a server response", () => {
    document.body.innerHTML = `
      <div data-button-loading>
        <button type="submit">
          <div class="prism-btn"><span>Continue</span><span class="prism-spinner"></span></div>
        </button>
      </div>
    `;

    uninstall = installButtonLoading();

    document.querySelector("button").click();

    const face = document.querySelector(".prism-btn");

    expect(face.classList).toContain("prism-btn-loading");
    expect(face.querySelector("span").classList).toContain("prism-btn-content");
  });
});
