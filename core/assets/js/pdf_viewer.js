import _ from "lodash";

import * as pdfjs from "pdfjs-dist";
import worker from "pdfjs-dist/build/pdf.worker.min.mjs";

const RESIZE_DEBOUNCE_MS = 100;

export const PDFViewer = {
  mounted() {
    console.log("[PDFViewer] Mounted: state", this.el.dataset.state);
    this.src = this.el.dataset.src;

    this.loadDocument().then((pdf) => {
      this.pdf = pdf;
      if (this.el.dataset.notifyReady !== "false") {
        console.log("[PDFViewer] Document loaded, push event 'pdf_ready'");
        this.pushEvent("pdf_ready");
      }
      this.renderPagesIfNeeded();

      this.onResize = _.debounce(() => {
        const width = this.el.getBoundingClientRect().width;
        if (this.container != undefined && width != this.renderedWidth) {
          this.renderPages();
        }
      }, RESIZE_DEBOUNCE_MS);
      window.addEventListener("resize", this.onResize);
    });
  },
  updated() {
    console.log("[PDFViewer] Updated: state", this.el.dataset.state);
    this.renderPagesIfNeeded();
  },
  destroyed() {
    if (this.onResize) {
      window.removeEventListener("resize", this.onResize);
      this.onResize.cancel();
    }
    this.cancelRender();
  },
  loadDocument() {
    pdfjs.GlobalWorkerOptions.workerSrc = worker;
    const loadingTask = pdfjs.getDocument({ url: this.src });
    return loadingTask.promise;
  },
  renderPagesIfNeeded() {
    console.log(
      "[PDFViewer] Render pages if need: state",
      this.el.dataset.state
    );
    if (this.el.dataset.state == "render" || this.container != undefined) {
      this.renderPages();
    }
  },
  // A new render supersedes any render still in flight: it cancels the
  // running page renders, and the superseded run stops at its next await.
  // Pages are rendered one after another into this run's own container, so
  // each page appears once, in order, at this run's width.
  async renderPages() {
    if (this.pdf == undefined) return;

    console.log("[PDFViewer] Render pages");
    this.cancelRender();
    const renderId = (this.renderId = (this.renderId ?? 0) + 1);
    const container = this.createContainer();
    const width = this.el.getBoundingClientRect().width;
    this.renderedWidth = width;

    for (let pageNum = 1; pageNum <= this.pdf.numPages; pageNum++) {
      const page = await this.pdf.getPage(pageNum);
      if (renderId != this.renderId) return;
      await this.renderPage(page, width, container);
      if (renderId != this.renderId) return;
    }
    console.log("[PDFViewer] end of document");
  },
  cancelRender() {
    this.renderTasks?.forEach((task) => task.cancel());
    this.renderTasks = [];
  },
  async renderPage(page, width, container) {
    console.log("[PDFViewer] Render page", page.pageNumber, width);
    var canvas = this.createCanvas(container);
    const context = canvas.getContext("2d");

    const pdfWidth = page.getViewport({ scale: 1 }).width;
    const viewport = page.getViewport({ scale: width / pdfWidth });
    const scale = viewport.width / pdfWidth;

    const ratio = window.devicePixelRatio || 1;
    canvas.width = viewport.width * ratio;
    canvas.height = viewport.height * ratio;
    canvas.style.width = viewport.width + "px";
    canvas.style.height = viewport.height + "px";
    context.scale(ratio, ratio);

    const renderTask = page.render({
      canvasContext: context,
      viewport: viewport,
    });
    this.renderTasks.push(renderTask);

    const annotations = await page.getAnnotations();

    function translateEventCoordinatesToPdfViewport(canvas, x, y) {
      const rect = canvas.getBoundingClientRect();
      const newx = (x - rect.left) / scale;
      const newy = (-1 * (y - rect.bottom)) / scale;
      return { x: newx, y: newy };
    }

    canvas.addEventListener("click", (event) => {
      const { x, y } = translateEventCoordinatesToPdfViewport(
        canvas,
        event.clientX,
        event.clientY
      );
      for (let annotation of annotations) {
        const rect = annotation.rect;
        if (x > rect[0] && x < rect[2] && y > rect[1] && y < rect[3]) {
          if (annotation.url) {
            window.open(annotation.url, "_blank");
          }
        }
      }
    });

    canvas.addEventListener("mousemove", (event) => {
      const { x, y } = translateEventCoordinatesToPdfViewport(
        canvas,
        event.clientX,
        event.clientY
      );
      for (let annotation of annotations) {
        const rect = annotation.rect;
        if (x > rect[0] && x < rect[2] && y > rect[1] && y < rect[3]) {
          canvas.style.cursor = "pointer";
          break;
        } else {
          canvas.style.cursor = "default";
        }
      }
    });

    try {
      await renderTask.promise;
    } catch (error) {
      if (!(error instanceof pdfjs.RenderingCancelledException)) throw error;
    }
  },
  createContainer() {
    if (this.container != undefined) {
      this.container.remove();
    }
    this.container = document.createElement("div");
    this.container.style.display = "block";
    this.el.appendChild(this.container);
    return this.container;
  },
  createCanvas(container) {
    var canvas = document.createElement("canvas");
    canvas.style.display = "block";
    container.appendChild(canvas);
    return canvas;
  },
};
