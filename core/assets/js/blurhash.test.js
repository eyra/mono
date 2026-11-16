import { beforeEach, describe, expect, it, vi } from "vitest";
import { Blurhash } from "./blurhash";

describe("Blurhash", () => {
  const mount = (attrs) => {
    document.body.innerHTML = `
      <div id="image" data-blurhash="LEHV6nWB2yk8pyo0adR*.7kCMdnj"
           data-image-width="10" data-image-height="10" data-src="/image.png"
           ${attrs}></div>
    `;
    const el = document.getElementById("image");

    const hook = Object.create(Blurhash);
    hook.el = el;
    hook.mounted();

    return el.getElementsByTagName("img")[0];
  };

  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("gives the image the alt it is given", () => {
    const img = mount(`data-alt=""`);

    expect(img.getAttribute("alt")).toBe("");
  });

  it("adds no alt when none is given", () => {
    const img = mount("");

    expect(img.hasAttribute("alt")).toBe(false);
  });
});
