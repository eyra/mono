export const UserState = {
  mounted() {
    console.log("[UserState] mounted");
    this.key = this.el.dataset.key;
    this.save();
  },
  updated() {
    console.log("[UserState] updated");
    this.save();
  },
  save() {
    const value = this.el.dataset.value;
    if (value === undefined) {
      console.log(
        "[UserState] save: value is undefined, removing key",
        this.key
      );
      window.localStorage.removeItem(this.key);
    } else {
      console.log(
        "[UserState] save: value is defined, setting key",
        this.key,
        value
      );
      window.localStorage.setItem(this.key, value);
    }
  },
};
