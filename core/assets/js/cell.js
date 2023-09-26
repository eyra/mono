const COLLAPSED = "collapsed";
const EXPANDED = "expanded";

const COLLAPSED_VIEW = "cell-collapsed-view";
const EXPANDED_VIEW = "cell-expanded-view";

const COLLAPSE_BUTTON = "cell-collapse-button";
const EXPAND_BUTTON = "cell-expand-button";

export const Cell = {
  mounted() {
    this.collapseButton = this.el.getElementsByClassName(COLLAPSE_BUTTON)[0];
    this.collapsedView = this.el.getElementsByClassName(COLLAPSED_VIEW)[0];

    this.expandButton = this.el.getElementsByClassName(EXPAND_BUTTON)[0];
    this.expandedView = this.el.getElementsByClassName(EXPANDED_VIEW)[0];

    this.collapseButton.addEventListener("click", (event) => {
      event.stopPropagation();
      this.updateStatus(COLLAPSED);
    });

    this.expandButton.addEventListener("click", (event) => {
      event.stopPropagation();
      this.updateStatus(EXPANDED);
    });

    var initialStatus = this.el.dataset.initialStatus
      ? this.el.dataset.initialTab
      : COLLAPSED;

    var savedStatus = this.loadStatus();
    this.status = savedStatus ? savedStatus : initialStatus;
    this.updateUI();
  },

  updated() {
    this.updateUI();
  },

  loadStatus() {
    const key = this.getStatusKey();
    const status = window.localStorage.getItem(key);
    if (typeof status === "string") {
      return status;
    }
    return undefined;
  },

  saveStatus() {
    console.info("saveStatus ", this.status);
    window.localStorage.setItem(this.getStatusKey(), this.status);
  },

  getStatusKey() {
    return "cell://" + this.el.id + "/status";
  },

  updateStatus(status) {
    this.status = status;
    this.saveStatus();
    this.updateUI();
  },

  updateUI() {
    if (this.status == EXPANDED) {
      this.hide(this.collapsedView);
      this.show(this.expandedView);
    } else {
      this.show(this.collapsedView);
      this.hide(this.expandedView);
    }
  },
  hide(element) {
    if (!element.classList.contains("hidden")) {
      element.classList.add("hidden");
    }
  },
  show(element) {
    element.classList.remove("hidden");
  },
};
