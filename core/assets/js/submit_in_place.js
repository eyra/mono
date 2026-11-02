import { clearClientLoading } from "./button_loading";

// SubmitInPlace
//
// LiveView hook for a form that stays on the page when the server answers
// with an error. LiveView's own `phx-submit` blurs the focused field and makes
// it readonly until the reply, and then focuses it again: on a phone the
// on-screen keyboard drops and comes back. This hook pushes the form's
// `phx-submit` event itself, so the focused field keeps its focus.
//
// The server may answer without re-rendering the submit button; the reply ends
// the loading feedback that `button_loading.js` started on submit.
//
// Markup contract:
//   <form id="..." phx-hook="SubmitInPlace" phx-submit="event"> ... </form>

export const SubmitInPlace = {
  mounted() {
    this.pending = false;
    this.onSubmit = this.handleSubmit.bind(this);
    this.el.addEventListener("submit", this.onSubmit);
  },

  destroyed() {
    this.el.removeEventListener("submit", this.onSubmit);
  },

  handleSubmit(event) {
    event.preventDefault();
    event.stopPropagation();
    if (this.pending) return;

    this.pending = true;
    const values = Object.fromEntries(new FormData(this.el));
    this.pushEvent(this.el.getAttribute("phx-submit"), values, () => {
      this.pending = false;
      clearClientLoading(this.el);
    });
  },
};
