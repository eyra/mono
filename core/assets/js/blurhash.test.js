import { beforeEach, describe, expect, it, vi } from "vitest";
import { Blurhash } from "./blurhash";

describe("Blurhash", () => {
  let el;

  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});

    document.body.innerHTML = `
      <div id="image" data-blurhash="LEHV6nWB2yk8pyo0adR*.7kCMdnj"
           data-image-width="10" data-image-height="10" data-src="/image.png"></div>
    `;
    el = document.getElementById("image");

    const hook = Object.create(Blurhash);
    hook.el = el;
    hook.mounted();
  });

  it("adds a decorative image", () => {
    const [img] = el.getElementsByTagName("img");

    expect(img.getAttribute("alt")).toBe("");
  });
});
