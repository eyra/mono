export const Sticky = {
  mounted() {
    this.initializeIfNeeded();
  },
  updated() {
    this.initializeIfNeeded();
  },
  initializeIfNeeded() {
    if (this.el.dataset.state == "visible" && this.originalTop == undefined) {
      this.initialize();
    }
  },
  initialize() {
    this.originalTop = this.el.getBoundingClientRect().top;
    this.originalRight = this.el.getBoundingClientRect().right;
    this.originalHeight = this.el.getBoundingClientRect().height;
    window.addEventListener("scroll", (event) => {
      var scrollY = 0;
      // Currently support for website and stripped layouts, not for workspace.
      // The event target in workspace layout is not the document.
      if (event.target == document) {
        scrollY = window.scrollY;
      }
      this.updateRect(scrollY);
    });
  },
  updateRect(scrollY) {
    if (scrollY >= this.originalTop) {
      if (this.el.classList.contains("absolute")) {
        console.log("fixed");
        this.el.classList.remove("absolute");
        this.el.classList.add("fixed");
        this.el.classList.add("top-0");
        this.el.classList.add("pr-[129px]");
      }
    } else {
      if (this.el.classList.contains("fixed")) {
        console.log("absolute");
        this.el.classList.remove("fixed");
        this.el.classList.remove("top-0");
        this.el.classList.remove("pr-[129px]");
        this.el.classList.add("absolute");
      }
    }
  },
};
