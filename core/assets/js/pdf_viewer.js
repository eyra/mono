import _ from "lodash";

const pdfjsVersion = "3.11.174";
const pdfjs = require("../node_modules/pdfjs-dist");
const worker = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsVersion}/pdf.worker.min.js`;

function renderPages(hook) {
  hook.renderPagesIfNeed();
}

export const PDFViewer = {
  mounted() {
    console.log("[PDFViewer] Mounted: state", this.el.dataset.state);
    this.src = this.el.dataset.src;

    this.loadDocument().then((pdf) => {
      this.pdf = pdf;
      console.log("[PDFViewer] Document loaded");
      this.pushEvent("tool_initialized");
      this.renderPagesIfNeed();
      var throttledRenderPages = _.throttle(_.partial(renderPages, this), 10, {
        trailing: true,
      });
      window.addEventListener("resize", throttledRenderPages);
    });
  },
  updated() {
    console.log("[PDFViewer] Updated: state", this.el.dataset.state);
    this.renderPagesIfNeed();
  },
  loadDocument() {
    pdfjs.GlobalWorkerOptions.workerSrc = worker;
    const loadingTask = pdfjs.getDocument({ url: this.src });
    return loadingTask.promise;
  },
  renderPagesIfNeed() {
    if (this.el.dataset.state == "visible") {
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
    console.log("[PDFViewer] Render page", pageNum);
    this.pdf.getPage(pageNum).then(
      (page) => {
        var scale = window.devicePixelRatio;
        var viewport = page.getViewport({ scale: scale });
        if (width < viewport.width) {
          scale = (width / viewport.width) * scale;
        }

        //This gives us the page's dimensions at full scale
        viewport = page.getViewport({ scale: scale });

        //We'll create a canvas for each page to draw it on
        const canvas = this.createCanvas(viewport);
        const context = canvas.getContext("2d");
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
  createCanvas(viewport) {
    var canvas = document.createElement("canvas");
    canvas.style.display = "block";
    canvas.height = viewport.height;
    canvas.width = viewport.width;
    this.container.appendChild(canvas);
    return canvas;
  },
};
