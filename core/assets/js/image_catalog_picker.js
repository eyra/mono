import { activateElement } from "./elements";

export const ImageCatalogPicker = {
  mounted() {
    console.log("[ImageCatalogPicker] Mounted");
    this.images = this.el.dataset.images;
    this.imageContainer = this.el.querySelector(".image-container");
    this.pages = Array.from(this.el.querySelectorAll('[id^="page-"]'));
    this.active_page = "1";
    this.refresh();
  },
  updated() {
    console.log("[ImageCatalogPicker] Updated");
    this.images = this.el.dataset.images;
    this.imageContainer = this.el.querySelector(".image-container");
    this.pages = Array.from(this.el.querySelectorAll('[id^="page-"]'));
    this.refresh();
  },
  refresh() {
    console.log("[ImageCatalogPicker] Refresh", this.imageContainer);
    this.renderImages();
    this.renderPages();
    this.startListen();
  },
  renderImages() {
    console.log("[ImageCatalogPicker] Render Images [", this.images, "]");
    if (this.images != undefined) {
      for (var i = 0; i < this.images.length; i++) {
        this.renderImage(i, i, "url", "srcset", "target");
      }
    } else {
      console.log("[ImageCatalogPicker] No Images");
    }
  },
  renderImage(id, index, url, srcset, target) {
    console.log("renderImage", id);
    const div = document.createElement("div");
    this.el.appendChild(div);
  },
  startListen() {
    console.log(this.pages);
    this.pages.forEach((page) => {
      page.addEventListener("click", (_event) => {
        if (this.active_page != page.dataset.page) {
          this.active_page = page.dataset.page;
          this.refresh();
        }
      });
    });
  },
  renderPages() {
    this.pages.forEach((page) => {
      console.log("PAGE", page.dataset.page);
      activateElement(page, page.dataset.page == this.active_page);
    });
  },
};
