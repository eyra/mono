import { decode } from "blurhash";

export const Blurhash = {
  mounted() {
    this.createElements();
    this.loadData();
    this.calculateFrame();
    this.initializeImg();

    this.render();
  },
  updated() {
    this.loadData();
    this.calculateFrame();
    this.render();
  },
  createElements() {
    this.createImg();
    this.createCanvas();
  },
  createImg() {
    this.img = document.createElement("img");
    this.img.style.width = "100%";
    this.img.style.height = "100%";
    this.img.style.objectFit = "cover";
    this.img.style.position = "absolute";
    this.img.style.top = "0";
    this.img.style.left = "0";
    this.img.style.zIndex = "10";
    this.img.style.opacity = "0";
    this.el.appendChild(this.img);
  },
  createCanvas() {
    this.canvas = document.createElement("canvas");
    this.canvas.style.width = "100%";
    this.canvas.style.height = "100%";
    this.canvas.style.objectFit = "cover";
    this.el.appendChild(this.canvas);
  },
  loadData() {
    this.imageWidth = parseInt(this.el.dataset.imageWidth, 10);
    this.imageHeight = parseInt(this.el.dataset.imageHeight, 10);
    this.style = this.el.dataset.style;
    this.blurhash = this.el.dataset.blurhash;
    // assign the src directly to the img
    this.img.src = this.el.dataset.src;
  },
  initializeImg() {
    this.img.style.opacity = this.img.complete ? "1" : "0";
    this.img.addEventListener("load", () => {
      this.img.style.transition = "opacity 0.5s ease-in-out";
      this.img.style.opacity = "1";
    });
  },
  initializeBlurhashContent() {
    this.blurhashContent.style.width = `${this.boundingWidth}px`;
    this.blurhashContent.style.height = `${this.boundingHeight}px`;
  },
  calculateFrame() {
    const boundingRect = this.el.getBoundingClientRect();
    this.boundingWidth = boundingRect.width;
    this.boundingHeight = boundingRect.height;

    if (this.style === "dynamic") {
      this.boundingHeight =
        this.boundingWidth * (this.imageHeight / this.imageWidth);
    }
  },
  render() {
    if (this.canvas === undefined) {
      console.log("[Blurhash] Canvas is undefined");
      return;
    }

    if (this.boundingWidth === 0 || this.boundingHeight === 0) {
      console.log("[Blurhash] Bounding rect is 0");
      return;
    }

    const canvasRatio = this.imageHeight / this.imageWidth;
    const canvasWidth = 32;
    const canvasHeight = Math.floor(canvasWidth * canvasRatio);

    this.canvas.width = canvasWidth;
    this.canvas.height = canvasHeight;

    const pixels = decode(this.blurhash, canvasWidth, canvasHeight);
    this.ctx = this.canvas.getContext("2d");
    const imageData = this.ctx.createImageData(canvasWidth, canvasHeight);
    imageData.data.set(pixels);
    this.ctx.putImageData(imageData, 0, 0);
  },
};
