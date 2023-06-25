const maxBottomMargin = 41;

export const SidePanel = {
  mounted() {
    this.parent = document.getElementById(this.el.dataset.parent);
    this.panel = this.el.getElementsByClassName("panel")[0];
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
    const scrollDelta =
      document.documentElement.scrollHeight -
      window.innerHeight -
      window.scrollY;
    const bottomMargin =
      maxBottomMargin - Math.min(maxBottomMargin, scrollDelta);

    const topDelta = Math.max(0, this.parent.getBoundingClientRect().top - window.scrollY);
    const height = Math.max(0, window.innerHeight - topDelta - bottomMargin);
    this.panel.style = `height: ${height}px;`;
  },
  updatePosition() {
    const top = Math.max(0,this.parent.getBoundingClientRect().top) + window.scrollY
    this.el.style = `top: ${top}px; right: 0px`;
  },
};
