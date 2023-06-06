const maxBottomMargin = 41;

export const SidePanel = {
  mounted() {
    this.startRect = this.el.getBoundingClientRect();
    this.panel = this.el.getElementsByClassName("panel")[0];
    this.panel.style = `height: 0px;`;
    this.el.classList.remove("relative");
    this.el.classList.add("absolute");

    this.updateFrame();

    window.addEventListener("scroll", (event) => {
      this.updateFrame();
    });

    window.addEventListener("resize", (event) => {
      this.updateFrame();
    });
  },
  updated() {
    this.updateFrame();
  },

  updateFrame() {
    this.updateHeight();
    this.updatePosition();
  },
  updateHeight() {
    const scrollDelta =
      document.documentElement.scrollHeight -
      window.innerHeight -
      window.scrollY;
    const bottomMargin =
      maxBottomMargin - Math.min(maxBottomMargin, scrollDelta);

    const topDelta = Math.max(0, this.startRect.y - window.scrollY);
    const height = Math.max(0, window.innerHeight - topDelta - bottomMargin);
    this.panel.style = `height: ${height}px;`;
  },
  updatePosition() {
    const top = Math.max(this.startRect.y, window.scrollY);
    this.el.style = `top: ${top}px; right: 0px`;
  },
};
