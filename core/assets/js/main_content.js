export const MainContent = {
  scrollToTop(from) {
    this.getEl().scrollTo(0, 0);
  },
  bottomDistance() {
    let el = this.getEl();
    return el.scrollHeight - el.scrollTop - window.innerHeight;
  },
  addScrollEventListener(callback) {
    this.getEl().addEventListener("scroll", callback);
  },
  getEl() {
    return document.getElementById("main-content");
  },
};
