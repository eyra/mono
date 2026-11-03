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
          <div class="prism-button prism-button--primary"><span class="prism-button__label">Continue</span></div>
        </button>
      </div>
    `;

    uninstall = installButtonLoading();

    document.querySelector("button").click();

    const face = document.querySelector(".prism-button");

    expect(face.classList).toContain("prism-button--loading");
    expect(
      face.querySelector(":scope > .prism-spinner.prism-spinner--20")
    ).not.toBeNull();
  });

  it("keeps the spinner of a face the server rendered loading", () => {
    document.body.innerHTML = `
      <div data-button-loading>
        <button type="submit">
          <div class="prism-button prism-button--primary prism-button--loading"><span class="prism-button__label">Continue</span><span class="prism-spinner prism-spinner--20"></span></div>
        </button>
      </div>
    `;

    uninstall = installButtonLoading();

    document.querySelector("button").click();

    expect(document.querySelectorAll(".prism-spinner")).toHaveLength(1);
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
            <div id="client" class="prism-button prism-button--primary"><span class="prism-button__label">Continue</span></div>
          </button>
        </div>
        <div id="server" class="prism-button prism-button--primary prism-button--loading"><span class="prism-button__label">Wait</span><span class="prism-spinner prism-spinner--20"></span></div>
      </form>
    `;

    const uninstall = installButtonLoading();
    document.querySelector("button").click();
    uninstall();

    clearClientLoading(document.querySelector("form"));

    const client = document.getElementById("client");
    const server = document.getElementById("server");

    expect(client.classList).not.toContain("prism-button--loading");
    expect(client.querySelector(".prism-spinner")).toBeNull();
    expect(server.classList).toContain("prism-button--loading");
    expect(server.querySelector(".prism-spinner")).not.toBeNull();
  });
});
