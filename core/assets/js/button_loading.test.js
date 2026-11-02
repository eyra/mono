import { afterEach, describe, expect, it } from "vitest";
import { clearClientLoading, installButtonLoading } from "./button_loading";

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

describe("clearClientLoading", () => {
  afterEach(() => {
    document.body.innerHTML = "";
  });

  it("ends the feedback it started and leaves a server-rendered loading face alone", () => {
    document.body.innerHTML = `
      <form>
        <div data-button-loading>
          <button type="submit">
            <div id="client" class="prism-btn"><span>Continue</span></div>
          </button>
        </div>
        <div id="server" class="prism-btn prism-btn-loading"><span class="prism-btn-content">Wait</span></div>
      </form>
    `;

    const uninstall = installButtonLoading();
    document.querySelector("button").click();
    uninstall();

    clearClientLoading(document.querySelector("form"));

    expect(document.getElementById("client").classList).not.toContain(
      "prism-btn-loading"
    );
    expect(document.getElementById("server").classList).toContain(
      "prism-btn-loading"
    );
  });
});
