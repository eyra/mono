// AuthCodeInput
//
// LiveView hook for a 6-digit OTP entry built from six single-char inputs.
//
// Markup contract:
//   <div phx-hook="AuthCodeInput" id="...">
//     <input data-otp-cell="0" maxlength="1" inputmode="numeric" autocomplete="one-time-code" />
//     <input data-otp-cell="1" maxlength="1" inputmode="numeric" />
//     ... (cells 0..5)
//     <input type="hidden" name="code" data-otp-value />
//   </div>
//
// Responsibilities:
//   - Auto-advance focus when a digit is typed
//   - Retreat focus on Backspace when the current cell is empty
//   - Distribute pasted text across cells
//   - Mirror the concatenated value into the hidden `code` field so the form
//     submits a single string

export const AuthCodeInput = {
  mounted() {
    this.cells = Array.from(this.el.querySelectorAll("[data-otp-cell]")).sort(
      (a, b) =>
        parseInt(a.dataset.otpCell, 10) - parseInt(b.dataset.otpCell, 10)
    );
    this.hidden = this.el.querySelector("[data-otp-value]");

    this.onInput = this.handleInput.bind(this);
    this.onKeyDown = this.handleKeyDown.bind(this);
    this.onPaste = this.handlePaste.bind(this);
    this.onFocus = this.handleFocus.bind(this);

    this.cells.forEach((cell) => {
      cell.addEventListener("input", this.onInput);
      cell.addEventListener("keydown", this.onKeyDown);
      cell.addEventListener("paste", this.onPaste);
      cell.addEventListener("focus", this.onFocus);
    });

    this.handleEvent("auth_code:clear", () => this.clearCells());

    if (this.cells[0]) this.cells[0].focus();
  },

  clearCells() {
    this.cells.forEach((cell) => (cell.value = ""));
    this.syncHidden();
    if (this.cells[0]) {
      requestAnimationFrame(() => this.cells[0].focus());
    }
  },

  destroyed() {
    this.cells.forEach((cell) => {
      cell.removeEventListener("input", this.onInput);
      cell.removeEventListener("keydown", this.onKeyDown);
      cell.removeEventListener("paste", this.onPaste);
      cell.removeEventListener("focus", this.onFocus);
    });
  },

  handleInput(event) {
    const cell = event.target;
    const digit = cell.value.replace(/\D/g, "").slice(-1);
    cell.value = digit;
    this.syncHidden();
    if (digit) {
      const next = this.cellAfter(cell);
      if (next) next.focus();
      else if (this.isComplete()) this.submitForm();
    }
  },

  handleKeyDown(event) {
    if (event.key !== "Backspace") return;
    const cell = event.target;
    if (cell.value === "") {
      const prev = this.cellBefore(cell);
      if (prev) {
        prev.value = "";
        this.syncHidden();
        prev.focus();
        event.preventDefault();
      }
    }
  },

  handlePaste(event) {
    const text = (event.clipboardData || window.clipboardData)
      .getData("text")
      .replace(/\D/g, "");
    if (!text) return;
    event.preventDefault();
    this.cells.forEach((cell, idx) => {
      cell.value = text[idx] || "";
    });
    this.syncHidden();
    const next = this.cells[Math.min(text.length, this.cells.length - 1)];
    if (next) next.focus();
    // Only auto-submit if the pasted text was exactly 6 digits — anything
    // longer is ambiguous (e.g. pasting prose containing the code) and the
    // user should review what got filled before submitting.
    if (text.length === this.cells.length) this.submitForm();
  },

  handleFocus(event) {
    event.target.select();
  },

  cellAfter(cell) {
    const idx = parseInt(cell.dataset.otpCell, 10);
    return this.cells[idx + 1] || null;
  },

  cellBefore(cell) {
    const idx = parseInt(cell.dataset.otpCell, 10);
    return idx > 0 ? this.cells[idx - 1] : null;
  },

  isComplete() {
    return this.cells.every((c) => /^\d$/.test(c.value));
  },

  syncHidden() {
    if (this.hidden) {
      this.hidden.value = this.cells.map((c) => c.value).join("");
    }
  },

  submitForm() {
    const form = this.el.closest("form");
    if (form) form.requestSubmit();
  },
};
