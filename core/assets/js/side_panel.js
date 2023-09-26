const maxBottomMargin = 63;

export const SidePanel = {
  mounted() {
    this.mainContent = document.getElementById("main-content");
    this.parent = document.getElementById(this.el.dataset.parent);
    this.panel = this.el.getElementsByClassName("panel")[0];
    this.panel.style = `position: fixed; height: 0px; top: 0px`;
    this.updateFrame();

    new ResizeObserver(() => {
      this.updateFrame();
    }).observe(this.parent);

    this.mainContent.addEventListener("scroll", (event) => {
      this.updateFrame();
    });

    window.addEventListener("resize", (event) => {
      this.updateFrame();
    });

    window.addEventListener("tab-activated", (event) => {
      this.updateFrame();
    });
  },
  updated() {
    this.updateFrame();
  },
  updateFrame() {
    const bottomDistance =
      this.mainContent.scrollHeight -
      this.mainContent.scrollTop -
      window.innerHeight;
    const bottomMargin =
      maxBottomMargin - Math.min(maxBottomMargin, bottomDistance);
    const topMargin = Math.max(0, this.parent.getBoundingClientRect().top);
    const height = window.innerHeight - (topMargin + bottomMargin);

    this.panel.style = `position: fixed; height: ${height}px; top: ${topMargin}px`;
  },
};
