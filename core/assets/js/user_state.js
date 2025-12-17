// Deprecated: DOM-based UserState hook for backward compatibility
// New architecture uses LiveSocket params + event bubbling (see phx:save_user_state listener below)
// TODO: Migrate remaining views (tabs, etc.) to new architecture and remove this hook
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

// Listen for save_user_state events from server (new architecture)
window.addEventListener("phx:save_user_state", (event) => {
  const { key, value } = event.detail;

  console.log("[UserState] phx:save_user_state:", key, value);

  if (value === null || value === undefined) {
    window.localStorage.removeItem(key);
  } else {
    window.localStorage.setItem(key, String(value));
  }
});
