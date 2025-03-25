import { MainContent } from "./main_content";

export const FullscreenImage = {
  mounted() {
    this.parent = document.getElementsByTagName("body")[0];

    this.el.addEventListener("click", (event) => {
      console.log("FullscreenImage clicked", event);
      this.showFullscreenImage();
    });
  },
  showFullscreenImage() {
    console.log("FullscreenImage showFullscreenImage");

    MainContent.hide();

    const modal = this.addModal();
    const modalImg = this.addModalImage(modal);
    this.setupZoom(modalImg);
    this.addCloseButton(modal);
  },
  addModal() {
    const modal = document.createElement("div");
    modal.classList.add("fullscreen-image-modal");

    // Style the modal to cover the whole page with black background
    modal.style.position = "fixed";
    modal.style.top = "0";
    modal.style.left = "0";
    modal.style.width = "100%";
    modal.style.height = "100%";
    modal.style.backgroundColor = "rgba(0, 0, 0, 1)";
    modal.style.zIndex = "9999";
    modal.style.display = "flex";
    modal.style.justifyContent = "center";
    modal.style.alignItems = "center";

    // Add click handler to close on background click
    modal.addEventListener("click", () => {
      this.hide(modal);
    });

    this.parent.appendChild(modal);

    return modal;
  },
  addModalImage(modal) {
    const img = this.el.querySelector("img");
    if (img) {
      // Create an image element for the modal
      const modalImg = document.createElement("img");
      modalImg.src = img.src;
      modalImg.style.objectFit = "contain";

      let scale = 1;
      let startDistance = 0;

      // Ensure image fits within viewport
      modalImg.style.maxWidth = "100%";
      modalImg.style.maxHeight = "100%";
      modalImg.style.height = "auto";
      modalImg.style.width = "auto";

      // Track touch points for pinch zoom
      modalImg.style.transform = `scale(${scale})`;
      modalImg.style.transformOrigin = "center";
      modalImg.style.transition = "transform 0.1s ease-out";

      // Prevent clicks on the image from closing the modal
      modalImg.addEventListener("click", (e) => {
        e.stopPropagation();
      });

      modal.appendChild(modalImg);

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
  setupZoom(modalImg) {
    // Setup for pinch zoom functionality
    let scale = 1;
    let startDistance = 0;

    // Ensure image fits within viewport
    modalImg.style.maxWidth = "100%";
    modalImg.style.maxHeight = "100%";
    modalImg.style.height = "auto";
    modalImg.style.width = "auto";

    // Track touch points for pinch zoom
    modalImg.style.transform = `scale(${scale})`;
    modalImg.style.transformOrigin = "center";
    modalImg.style.transition = "transform 0.1s ease-out";

    // Handle touch start to detect pinch
    modalImg.addEventListener("touchstart", (e) => {
      if (e.touches.length === 2) {
        startDistance = Math.hypot(
          e.touches[0].pageX - e.touches[1].pageX,
          e.touches[0].pageY - e.touches[1].pageY
        );
      }
    });

    // Handle touch move for pinch zoom
    modalImg.addEventListener("touchmove", (e) => {
      if (e.touches.length === 2) {
        e.preventDefault(); // Prevent page scrolling during pinch

        const currentDistance = Math.hypot(
          e.touches[0].pageX - e.touches[1].pageX,
          e.touches[0].pageY - e.touches[1].pageY
        );

        if (startDistance > 0) {
          const newScale = scale * (currentDistance / startDistance);
          // Limit scale between 0.5 and 5
          scale = Math.min(Math.max(newScale, 0.5), 5);
          modalImg.style.transform = `scale(${scale})`;
        }

        startDistance = currentDistance;
      }
    });

    // Reset zoom on double tap
    let lastTap = 0;
    modalImg.addEventListener("touchend", (e) => {
      const currentTime = new Date().getTime();
      const tapLength = currentTime - lastTap;
      if (tapLength < 300 && tapLength > 0) {
        scale = 1;
        modalImg.style.transform = `scale(${scale})`;
      }
      lastTap = currentTime;
    });
  },
  hide(modal) {
    this.parent.removeChild(modal);
    MainContent.show();
  },
};
