import _ from "lodash";

const pdfjsVersion = "3.11.174";
const pdfjs = require("../node_modules/pdfjs-dist");
const worker = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsVersion}/pdf.worker.min.js`;

function renderPages(hook) {
  hook.renderPagesIfNeeded();
}

export const PDFViewer = {
  mounted() {
    console.log("[PDFViewer] Mounted: state", this.el.dataset.state);
    this.src = this.el.dataset.src;

    this.loadDocument().then((pdf) => {
      this.pdf = pdf;
      console.log("[PDFViewer] Document loaded, push event 'tool_initialized'");
      this.pushEvent("tool_initialized");
      this.renderPagesIfNeeded();
      var throttledRenderPages = _.throttle(_.partial(renderPages, this), 10, {
        trailing: true,
      });

      window.addEventListener("resize", (event) => {
        console.log("[PDFViewer] Resize event");
        throttledRenderPages();
      });
    });
  },
  updated() {
    console.log("[PDFViewer] Updated: state", this.el.dataset.state);
    this.renderPagesIfNeeded();
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
  renderPages() {
    console.log("[PDFViewer] Render pages");
    this.createContainer();
    const width = this.el.getBoundingClientRect().width;
    this.renderPage(width, 1);
  },
  renderPage(width, pageNum) {
    console.log("[PDFViewer] Render page", pageNum, width);
    this.pdf.getPage(pageNum).then(
      async (page) => {
        var canvas = this.createCanvas();
        const context = canvas.getContext("2d");

        const pdfWidth = page.getViewport({ scale: 1 }).width;
        const viewport = page.getViewport({ scale: width / pdfWidth });
        const scale = viewport.width / pdfWidth;

        console.log("[PDFViewer] width", width);
        console.log("[PDFViewer] pdfWidth", pdfWidth);
        console.log("[PDFViewer] viewport.width", viewport.width);

        canvas.width = viewport.width;
        canvas.height = viewport.height;

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

        page.render({ canvasContext: context, viewport: viewport });

        this.renderPage(width, pageNum + 1);
      },
      () => {
        console.log("[PDFViewer] end of document");
      }
    );
  },
  createContainer() {
    if (this.container != undefined) {
      this.container.remove();
      this.container = undefined;
    }
    this.container = document.createElement("div");
    this.container.style.display = "block";
    this.el.appendChild(this.container);
  },
  createCanvas() {
    var canvas = document.createElement("canvas");
    canvas.style.display = "block";
    this.container.appendChild(canvas);
    return canvas;
  },
};
