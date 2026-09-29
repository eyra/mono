const ATTEMPT_PREFIX = "feldspar:attempt:";
const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function scopePrefix(scope) {
  return `${ATTEMPT_PREFIX}${encodeURIComponent(scope)}:`;
}

function attemptKeys(scope) {
  if (!scope) return [];
  try {
    const prefix = scopePrefix(scope);
    return Object.keys(window.localStorage).filter((key) =>
      key.startsWith(prefix)
    );
  } catch {
    return [];
  }
}

function storedAttempts(scope) {
  return attemptKeys(scope).flatMap((key) => {
    try {
      const value = window.localStorage.getItem(key);
      const marker = JSON.parse(value);
      if (
        !marker ||
        Object.keys(marker).length !== 2 ||
        !UUID.test(marker.attempt_id) ||
        key !== `${scopePrefix(scope)}${marker.attempt_id}` ||
        !Number.isFinite(marker.started_at)
      ) {
        return [];
      }
      return [{ key, value, ...marker }];
    } catch {
      return [];
    }
  });
}

function removeKey(key, expectedValue) {
  try {
    if (
      expectedValue === undefined ||
      window.localStorage.getItem(key) === expectedValue
    ) {
      window.localStorage.removeItem(key);
    }
  } catch {
    // Recovery is best effort when browser storage is unavailable.
  }
}

// The exit acknowledgment can arrive after LiveView has removed both hooks.
// A captured scope and unique attempt ID still allow clearing only that attempt.
export function clearFeldsparAttempt(scope, attemptId) {
  if (scope && UUID.test(attemptId)) {
    removeKey(`${scopePrefix(scope)}${attemptId}`);
  }
}

async function withAttemptLock(key, callback) {
  let entered = false;
  try {
    if (navigator.locks?.request) {
      return await navigator.locks.request(
        key,
        { ifAvailable: true },
        (lock) => {
          entered = true;
          return callback(Boolean(lock));
        }
      );
    }
  } catch (error) {
    if (entered) throw error;
  }
  return callback(null);
}

function newAttemptId() {
  if (crypto.randomUUID) return crypto.randomUUID();
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  const hex = Array.from(bytes, (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(
    12,
    16
  )}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

export const FeldsparRecovery = {
  mounted() {
    this.scope = this.el.dataset.recoveryScope;
    this.entryAttempts =
      this.el.dataset.recoveryOnEntry === "clear_previous"
        ? storedAttempts(this.scope)
        : null;
    this.ignoredEntryAttempts = new Map();
    this.recoveredAttempts = [];
    this.attempt = null;
    this.releaseLock = null;
    this.disposed = false;
    this.starting = false;
    this.generation = 0;

    this.terminalListener = (event) => {
      if (this.attempt?.attempt_id === event.detail?.attempt_id) {
        this.generation++;
        this.clearOwnedAttempt();
      }
    };
    this.closeListener = (event) => {
      const button = event.target.closest?.('[phx-click="close_modal"]');
      if (
        this.el.dataset.modalId &&
        button?.getAttribute("phx-value-item") === this.el.dataset.modalId
      ) {
        this.cancelAttempt();
      }
    };
    this.el.addEventListener("feldspar:terminal", this.terminalListener);
    document.addEventListener("click", this.closeListener, true);
    this.prepareRef = this.handleEvent("feldspar:prepare", ({ id }) => {
      if (id === this.el.id) return this.prepareStart();
    });
    this.checking = this.checkRecovery();
    return this.checking;
  },

  disconnected() {
    this.generation++;
    this.starting = false;
  },

  reconnected() {
    this.generation++;
    this.starting = false;
    const interruptedAttemptId =
      this.attempt?.attempt_id ||
      this.recoveredAttempts.find((attempt) => attempt.owned)?.attempt_id;
    this.releaseOwnedAttempt();
    this.checking = this.checkRecovery(interruptedAttemptId);
    return this.checking;
  },

  async checkRecovery(interruptedAttemptId) {
    const generation = this.generation;
    const clearPrevious = this.entryAttempts !== null;
    const candidates = (
      this.entryAttempts || storedAttempts(this.scope)
    ).filter(
      (attempt) => this.ignoredEntryAttempts.get(attempt.key) !== attempt.value
    );
    const checked = await Promise.all(
      candidates.map((attempt) =>
        attempt.attempt_id === interruptedAttemptId
          ? { ...attempt, owned: true }
          : withAttemptLock(attempt.key, (available) => {
              if (available === false) return null;
              if (
                clearPrevious &&
                available === true &&
                !this.disposed &&
                generation === this.generation
              )
                removeKey(attempt.key, attempt.value);
              return attempt;
            })
      )
    );
    if (this.disposed || generation !== this.generation) return;
    if (clearPrevious) {
      // Unknown ownership cannot be retired safely, but must not revive this
      // entry's stale recovery when the retained hook reconnects.
      checked.filter(Boolean).forEach((attempt) => {
        this.ignoredEntryAttempts.set(attempt.key, attempt.value);
      });
      this.entryAttempts = null;
      this.recoveredAttempts = [];
    } else {
      this.recoveredAttempts = checked.filter(Boolean);
    }
    try {
      await this.pushEvent("feldspar_recovery_checked", {
        unfinished:
          !clearPrevious &&
          (Boolean(interruptedAttemptId) || this.recoveredAttempts.length > 0),
      });
    } catch {
      // A disconnected LiveView must not affect the persisted attempt.
    }
  },

  async retireRecoveredAttempts(attempts) {
    await Promise.all(
      attempts.map((attempt) =>
        withAttemptLock(attempt.key, (available) => {
          // Only our own interrupted marker is safe to retire without Web Locks.
          if (available === true || (available === null && attempt.owned))
            removeKey(attempt.key, attempt.value);
        })
      )
    );
  },

  async prepareStart() {
    if (this.disposed || this.starting || this.attempt) return;
    this.starting = true;
    const generation = this.generation;
    try {
      await this.checking;
      if (this.disposed || generation !== this.generation) return;
      const attemptId = newAttemptId();
      const key = `${scopePrefix(this.scope)}${attemptId}`;
      const release = await new Promise((resolve) => {
        withAttemptLock(key, (available) => {
          if (available === true)
            return new Promise((unlock) => resolve(unlock));
          resolve(() => {});
        });
      });
      if (this.disposed || generation !== this.generation) {
        release();
        return;
      }
      this.releaseLock = release;
      this.attempt = { attempt_id: attemptId, started_at: Date.now() };
      try {
        if (this.scope)
          window.localStorage.setItem(key, JSON.stringify(this.attempt));
      } catch {
        // Storage denial must not prevent the explicit start action.
      }
      const recovered = this.recoveredAttempts;
      this.recoveredAttempts = [];
      // Write the replacement first, so interruption during retirement stays recoverable.
      await this.retireRecoveredAttempts(recovered);
      if (this.disposed || generation !== this.generation) return;
      await this.pushEvent("start", { attempt_id: attemptId });
    } catch {
      // Retain the marker if LiveView disconnects while starting.
    } finally {
      if (generation === this.generation) this.starting = false;
    }
  },

  clearOwnedAttempt() {
    if (this.attempt) clearFeldsparAttempt(this.scope, this.attempt.attempt_id);
    this.releaseOwnedAttempt();
  },

  releaseOwnedAttempt() {
    this.attempt = null;
    this.releaseLock?.();
    this.releaseLock = null;
  },

  cancelAttempt() {
    this.generation++;
    this.clearOwnedAttempt();
    const recovered = this.recoveredAttempts;
    this.recoveredAttempts = [];
    return this.retireRecoveredAttempts(recovered);
  },

  destroyed() {
    this.disposed = true;
    this.generation++;
    this.el.removeEventListener("feldspar:terminal", this.terminalListener);
    document.removeEventListener("click", this.closeListener, true);
    this.removeHandleEvent(this.prepareRef);
    this.releaseLock?.();
    this.releaseLock = null;
    // Navigation and tab loss are not cancellation: retain the attempt marker.
  },
};
