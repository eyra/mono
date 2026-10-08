// In the native app the document scrolls instead of #main-content (workspace layout).
const nativeApp = () => document.body.hasAttribute("data-native-app");

export const MainContent = {
  scrollToTop(from) {
    this.scroller().scrollTo(0, 0);
  },
  bottomDistance() {
    let el = this.scroller();
    return el.scrollHeight - el.scrollTop - window.innerHeight;
  },
  addScrollEventListener(callback) {
    (nativeApp() ? window : this.getEl()).addEventListener("scroll", callback);
  },
  scroller() {
    return nativeApp() ? document.scrollingElement : this.getEl();
  },
  getEl() {
    return document.getElementById("main-content");
  },
  hide() {
    this.getEl().style.display = "none";
  },
  show() {
    this.getEl().style.display = "block";
  },
};
