import { MainContent } from "./main_content";
import PinchZoom from "pinch-zoom-js";

export const FullscreenImage = {
  mounted() {
    this.parent = document.getElementsByTagName("body")[0];

    this.el.addEventListener("click", (event) => {
      this.showFullscreenImage();
    });
  },
  showFullscreenImage() {
    MainContent.hide();

    const overlay = this.addOverlay();
    const imgContainer = this.addImageContainer(overlay);
    this.addImage(imgContainer);
    this.addCloseButton(overlay);
    this.pz = new PinchZoom(imgContainer, {});
  },
  addOverlay() {
    const overlay = document.createElement("div");
    overlay.classList.add("fullscreen-image-overlay");
    overlay.style.backgroundColor = "rgba(0, 0, 0, 1)";
    overlay.style.width = "100vw";
    overlay.style.height = "100vh";
    overlay.style.position = "fixed";
    overlay.style.top = "0";
    overlay.style.left = "0";
    overlay.style.zIndex = "9999";

    this.parent.appendChild(overlay);

    return overlay;
  },
  addImageContainer(overlay) {
    const imgContainer = document.createElement("div");
    imgContainer.classList.add("fullscreen-image-container");
    imgContainer.style.backgroundColor = "rgba(0, 0, 0, 1)";
    imgContainer.style.width = "100vw";
    imgContainer.style.height = "100vh";
    imgContainer.style.display = "flex";
    imgContainer.style.justifyContent = "center";
    imgContainer.style.alignItems = "center";

    overlay.appendChild(imgContainer);
    return imgContainer;
  },
  addImage(imgContainer) {
    const img = this.el.querySelector("img");
    if (img) {
      // Create an image element for the modal
      const modalImg = document.createElement("img");
      modalImg.src = img.src;
      modalImg.style.maxWidth = "100vw";
      modalImg.style.maxHeight = "100vh";

      imgContainer.appendChild(modalImg);

      return modalImg;
    }
    return null;
  },
  addCloseButton(modal) {
    const closeBtn = document.createElement("div");
    closeBtn.innerHTML = `<img src="/images/icons/close_light.svg" alt="Close" width="24" height="24">`;
    closeBtn.style.position = "absolute";
    closeBtn.style.top = "24px";
    closeBtn.style.right = "32px";
    closeBtn.style.cursor = "pointer";

    closeBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      this.hide(modal);
    });

    modal.appendChild(closeBtn);
  },
  hide(modal) {
    this.pz.destroy();
    this.parent.removeChild(modal);
    MainContent.show();
  },
};
