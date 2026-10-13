import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("pdfjs-dist", () => ({ GlobalWorkerOptions: {} }));
vi.mock("pdfjs-dist/build/pdf.worker.min.mjs", () => ({ default: "worker" }));

import { PDFViewer } from "./pdf_viewer";

const PAGE_COUNT = 4;
const PDF_PAGE_WIDTH = 100;

const tick = () => new Promise((resolve) => setTimeout(resolve, 0));

async function settle() {
  for (let i = 0; i < 50; i++) await tick();
}

function fakePdf(renderedPages) {
  return {
    numPages: PAGE_COUNT,
    getPage(pageNum) {
      if (pageNum > PAGE_COUNT) return Promise.reject(new Error("no page"));
      // Later pages take longer, so overlapping render runs interleave.
      return new Promise((resolve) =>
        setTimeout(() => resolve(fakePage(pageNum, renderedPages)), pageNum)
      );
    },
  };
}

function fakePage(pageNum, renderedPages) {
  return {
    getViewport: ({ scale }) => ({
      width: PDF_PAGE_WIDTH * scale,
      height: PDF_PAGE_WIDTH * 1.4 * scale,
    }),
    getAnnotations: () => Promise.resolve([]),
    render: ({ canvasContext }) => {
      renderedPages.set(canvasContext.canvas, pageNum);
      return { promise: tick(), cancel: vi.fn() };
    },
  };
}

function mountHook(width) {
  const el = document.createElement("div");
  el.getBoundingClientRect = () => ({ width });
  document.body.appendChild(el);

  const renderedPages = new Map();
  const hook = Object.create(PDFViewer);
  hook.el = el;
  hook.pdf = fakePdf(renderedPages);

  return {
    hook,
    setWidth: (w) => (el.getBoundingClientRect = () => ({ width: w })),
    canvases: () => [...el.querySelectorAll("canvas")],
    pageOf: (canvas) => renderedPages.get(canvas),
  };
}

describe("PDFViewer", () => {
  beforeEach(() => {
    vi.spyOn(HTMLCanvasElement.prototype, "getContext").mockImplementation(
      function () {
        return { canvas: this, scale: vi.fn() };
      }
    );
  });

  afterEach(() => {
    vi.restoreAllMocks();
    document.body.innerHTML = "";
  });

  it("renders each page once, in order", async () => {
    const viewer = mountHook(800);

    viewer.hook.renderPages();
    await settle();

    expect(viewer.canvases().map(viewer.pageOf)).toEqual([1, 2, 3, 4]);
  });

  it("renders each page once, in order, at the last width after overlapping re-renders", async () => {
    const viewer = mountHook(800);

    viewer.hook.renderPages();
    await tick();
    await tick();
    viewer.setWidth(500);
    viewer.hook.renderPages();
    await tick();
    viewer.setWidth(300);
    viewer.hook.renderPages();
    await settle();

    const canvases = viewer.canvases();
    expect(canvases.map(viewer.pageOf)).toEqual([1, 2, 3, 4]);
    expect(canvases.map((c) => c.style.width)).toEqual(
      Array(PAGE_COUNT).fill("300px")
    );
  });
});
