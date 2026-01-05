// User state management
// Limits items sent to server to prevent WebSocket URL overflow in Safari

const MAX_USER_STATE_ITEMS = 20;
const USER_STATE_PREFIX = "next://";

// Get all keys matching our prefix
function getUserStateKeys() {
  const keys = [];
  for (let i = 0; i < window.localStorage.length; i++) {
    const key = window.localStorage.key(i);
    if (key && key.startsWith(USER_STATE_PREFIX)) {
      keys.push(key);
    }
  }
  return keys;
}

// Purge oldest items if over limit
function purgeOldItems() {
  const keys = getUserStateKeys();
  if (keys.length > MAX_USER_STATE_ITEMS) {
    // Remove oldest items (first in array)
    const keysToRemove = keys.slice(0, keys.length - MAX_USER_STATE_ITEMS);
    for (const key of keysToRemove) {
      window.localStorage.removeItem(key);
    }
  }
}

// Save user state with automatic purging
function saveUserState(key, value) {
  if (value === null || value === undefined) {
    window.localStorage.removeItem(key);
  } else {
    window.localStorage.setItem(key, String(value));
    // Purge after insert if it's a tracked key
    if (key.startsWith(USER_STATE_PREFIX)) {
      purgeOldItems();
    }
  }
}

// Get user state items to send to server (filtered and limited)
export function getAllUserState() {
  const result = {};
  const keys = getUserStateKeys();

  // Take only the last N items
  const limitedKeys = keys.slice(-MAX_USER_STATE_ITEMS);

  for (const key of limitedKeys) {
    const value = window.localStorage.getItem(key);
    if (value !== null) {
      result[key] = value;
    }
  }

  return result;
}

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
      saveUserState(this.key, null);
    } else {
      console.log(
        "[UserState] save: value is defined, setting key",
        this.key,
        value
      );
      saveUserState(this.key, value);
    }
  },
};

// Listen for save_user_state events from server (new architecture)
window.addEventListener("phx:save_user_state", (event) => {
  const { key, value } = event.detail;

  console.log("[UserState] phx:save_user_state:", key, value);
  saveUserState(key, value);
});
