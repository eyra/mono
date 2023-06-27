const maxBottomMargin = 62;

export const SidePanel = {
  mounted() {
    this.parent = document.getElementById(this.el.dataset.parent);
    this.panel = this.el.getElementsByClassName("panel")[0];
    this.panel.style = `height: 0px;`;
    this.make_absolute();
    this.updateFrame();

    window.addEventListener("tab-activated", (event) => {
      this.updateFrame();
    });

    window.addEventListener("scroll", (event) => {
      this.updateFrame();
    });

    window.addEventListener("resize", (event) => {
      this.updateFrame();
    });
  },
  make_absolute() {
    this.el.classList.remove("relative");
    this.el.classList.add("absolute");
  },
  updated() {
    this.make_absolute();
    this.updateFrame();
  },
  updateFrame() {
    this.updateHeight();
    this.updatePosition();
  },
  updateHeight() {
    const bottomMarginDelta = Math.min(
      maxBottomMargin,
      document.documentElement.scrollHeight -
        window.scrollY -
        window.innerHeight
    );
    const bottomMargin = maxBottomMargin - bottomMarginDelta;

    const height =
      window.innerHeight -
      (this.parent.getBoundingClientRect().top + bottomMargin);
    this.panel.style = `height: ${height}px;`;
  },
  updatePosition() {
    const top =
      Math.max(0, this.parent.getBoundingClientRect().top) + window.scrollY;
    this.el.style = `top: ${top}px; right: 0px`;
  },
};
