export const UserStateObserver = {
  mounted() {
    console.log("[UserStateObserver] mounted");
    var data = Object.assign({}, window.localStorage);

    this.notifyData(data);
    this.notifyInitialized();
  },
  updated() {
    console.log("[UserStateObserver] updated");
    if (!this.isInitialized()) {
      var data = Object.assign({}, window.localStorage);
      this.notifyData(data);
      this.notifyInitialized();
    }
  },
  isInitialized() {
    return this.el.dataset.initialized != void 0;
  },
  notifyInitialized() {
    this.pushEventTo(this.el, "user_state_initialized", {
      key: this.key,
    });
  },
  notifyData(data) {
    this.pushEventTo(this.el, "user_state_data", {
      data: data,
    });
  },
};
