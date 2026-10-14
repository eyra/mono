import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("pdfjs-dist/legacy/build/pdf.mjs", () => ({ GlobalWorkerOptions: {} }));
vi.mock("pdfjs-dist/legacy/build/pdf.worker.min.mjs", () => ({
  default: "worker",
}));

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
    loadingTask: { destroy: vi.fn() },
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

// Like the participant page: the viewer is as wide as the window, or as its
// widest rendered page when that is wider.
function mountHook(width) {
  const el = document.createElement("div");
  let windowWidth;
  const setWidth = (w) => {
    windowWidth = w;
    Object.defineProperty(window, "innerWidth", {
      value: w,
      configurable: true,
    });
  };
  setWidth(width);
  el.getBoundingClientRect = () => ({
    width: Math.max(
      windowWidth,
      ...[...el.querySelectorAll("canvas")].map((c) =>
        parseFloat(c.style.width)
      )
    ),
  });
  document.body.appendChild(el);

  const renderedPages = new Map();
  const hook = Object.create(PDFViewer);
  hook.el = el;
  hook.pdf = fakePdf(renderedPages);
  hook.loadDocument = () => Promise.resolve(hook.pdf);

  return {
    hook,
    setWidth,
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

  describe("on resize", () => {
    beforeEach(() => vi.useFakeTimers());
    afterEach(() => vi.useRealTimers());

    async function mountViewer(width) {
      const viewer = mountHook(width);
      viewer.hook.el.dataset.state = "render";
      viewer.hook.el.dataset.notifyReady = "false";
      viewer.hook.mounted();
      await vi.advanceTimersByTimeAsync(1000);
      vi.spyOn(viewer.hook, "renderPages");
      return viewer;
    }

    const resize = () => window.dispatchEvent(new Event("resize"));

    it("re-renders once at the narrower width, 100 ms after the last resize event", async () => {
      const viewer = await mountViewer(800);

      viewer.setWidth(500);
      resize();
      await vi.advanceTimersByTimeAsync(60);
      resize();
      await vi.advanceTimersByTimeAsync(60);
      expect(viewer.hook.renderPages).not.toHaveBeenCalled();

      await vi.advanceTimersByTimeAsync(1000);
      expect(viewer.hook.renderPages).toHaveBeenCalledTimes(1);
      expect(viewer.canvases().map((c) => c.style.width)).toEqual(
        Array(PAGE_COUNT).fill("500px")
      );
    });

    it("does not re-render when the width did not change", async () => {
      const viewer = await mountViewer(800);

      resize();
      await vi.advanceTimersByTimeAsync(1000);

      expect(viewer.hook.renderPages).not.toHaveBeenCalled();
    });

    it("stops rendering and listening once destroyed", async () => {
      const viewer = await mountViewer(800);

      viewer.setWidth(500);
      resize();
      await vi.advanceTimersByTimeAsync(100);
      const canvasCount = viewer.canvases().length;
      viewer.hook.destroyed();
      await vi.advanceTimersByTimeAsync(1000);

      expect(viewer.canvases().length).toBe(canvasCount);
      expect(canvasCount).toBeLessThan(PAGE_COUNT);
      expect(viewer.hook.pdf.loadingTask.destroy).toHaveBeenCalled();

      viewer.setWidth(300);
      resize();
      await vi.advanceTimersByTimeAsync(1000);
      expect(viewer.hook.renderPages).toHaveBeenCalledTimes(1);
    });
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
