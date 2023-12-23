// import * as pdfjsLib from 'pdfjs-dist'

export const PDFViewer = {
  mounted() {
    console.log("Mounted");
    this.src = this.el.dataset.src;
    console.log("src", this.src);
    // pdfjsLib.getDocument(this.src)
    // renderPDF(this.el, this.el.dataset.src);
  },
};

// function renderPDF(canvas, src) {
//   pdfjsLib.GlobalWorkerOptions.workerSrc = '../node_modules/pdfjs-dist/build/pdf.worker.js';

//   let currentPageNum = 1;

//   // Handle hidi
//   const outputScale = window.devicePixelRatio || 1;

//   function adjustCanvasSize(viewport) {
//     canvas.width = Math.floor(viewport.width * outputScale);
//     canvas.height = Math.floor(viewport.height * outputScale);
//     canvas.style.width = Math.floor(viewport.width) + 'px';
//     canvas.style.height = Math.floor(viewport.height) + 'px';
//   }

//   const loadingTask = pdfjsLib.getDocument(src);
//   (async () => {
//     const pdf = await loadingTask.promise;
//     let page = await pdf.getPage(1);
//     const viewport = page.getViewport({ scale: 1.5 });

//     const context = canvas.getContext('2d');
//     adjustCanvasSize(viewport);
//     canvas.classList.add('border', 'border-purple-500', 'rounded');

//     const transform = outputScale !== 1
// 	  ? [outputScale, 0, 0, outputScale, 0, 0]
// 	  : null;

//     let renderContext = {
//       canvasContext: context,
//       transform,
//       viewport,
//     };

//     page.render(renderContext);

//     async function onPrevPage() {
//       if (currentPageNum <= 1) {
// 	return;
//       }
//       currentPageNum -= 1;
//       page = await pdf.getPage(currentPageNum);
//       page.render(renderContext);
//     }

//     async function onNextPage() {
//       if (currentPageNum >= pdf.numPages) {
// 	return;
//       }
//       currentPageNum += 1;
//       page = await pdf.getPage(currentPageNum);
//       page.render(renderContext);
//     }

//     async function onZoom(e) {
//       const newViewport = page.getViewport({ scale: parseFloat(e.target.value) });
//       adjustCanvasSize(newViewport);
//       renderContext.viewport = newViewport;
//       page = await pdf.getPage(currentPageNum);
//       page.render(renderContext);
//     }

//     document.querySelector('.js-next').addEventListener('click', onNextPage);
//     document.querySelector('.js-prev').addEventListener('click', onPrevPage)
//     document.querySelector('.js-zoom').addEventListener('click', onZoom)
//   })();
// }
