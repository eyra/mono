import _ from "lodash";

function handleResize(hook) {
  hook.handleResize();
}

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
    this.defaultClasslist = this.el.dataset.classDefault.split(" ");
    this.stickyClasslist = this.el.dataset.classSticky.split(" ");

    this.makeScrolling();
    this.updateOriginalPosition();

    window.addEventListener("scroll", (event) => {
      var scrollY = 0;
      // Currently support for website and stripped layouts, not for workspace.
      // The event target in workspace layout is not the document.
      if (event.target == document) {
        scrollY = window.scrollY;
      }
      this.updateRect(scrollY);
    });

    var throttledHandleResize = _.throttle(_.partial(handleResize, this), 10, {
      trailing: true,
    });
    window.addEventListener("resize", throttledHandleResize);
  },
  handleResize() {
    console.log("RESIZE");
    this.makeScrolling();
    this.updateOriginalPosition();
  },
  updateOriginalPosition() {
    this.originalTop = this.el.getBoundingClientRect().top;
    this.originalRight = this.el.getBoundingClientRect().right;
    this.originalHeight = this.el.getBoundingClientRect().height;
  },
  updateRect(scrollY) {
    if (scrollY >= this.originalTop) {
      if (this.el.classList.contains("absolute")) {
        this.makeSticky();
      }
    } else {
      if (this.el.classList.contains("fixed")) {
        this.makeScrolling();
      }
    }
  },
  makeScrolling() {
    this.stickyClasslist.forEach((clazz) => {
      this.el.classList.remove(clazz);
    });
    this.defaultClasslist.forEach((clazz) => {
      this.el.classList.add(clazz);
    });
  },
  makeSticky() {
    this.defaultClasslist.forEach((clazz) => {
      this.el.classList.remove(clazz);
    });
    this.stickyClasslist.forEach((clazz) => {
      this.el.classList.add(clazz);
    });
  },
};
