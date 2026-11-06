// The server's next render of a face drops this marker; a face that still has
// it after the reply was not re-rendered and still shows the loading feedback.
const CLIENT_LOADING = "data-client-loading";

// Prism's button renders its spinner only while it is loading, so a face the
// client sets loading gets the spinner Prism's loading button has.
const addSpinner = (face) => {
  if (face.querySelector(":scope > .prism-spinner")) return;

  const spinner = document.createElement("span");
  spinner.className = "prism-spinner prism-spinner--20";
  spinner.setAttribute(CLIENT_LOADING, "");
  face.appendChild(spinner);
};

const activateLoading = (element) => {
  const face = element?.querySelector(".prism-button");
  if (!face) return;

  face.classList.add("prism-button--loading");
  face.setAttribute(CLIENT_LOADING, "");
  addSpinner(face);
};

export const clearClientLoading = (root) => {
  root.querySelectorAll(`.prism-button[${CLIENT_LOADING}]`).forEach((face) => {
    face.classList.remove("prism-button--loading");
    face.removeAttribute(CLIENT_LOADING);
    face.querySelector(`:scope > .prism-spinner[${CLIENT_LOADING}]`)?.remove();
  });
};

export const installButtonLoading = () => {
  const onClick = (event) =>
    activateLoading(event.target.closest?.("[data-button-loading]"));

  const onSubmit = (event) => {
    const button = event.submitter?.closest?.("[data-button-loading]");
    activateLoading(
      button || event.target.querySelector("[data-button-loading]")
    );
  };

  document.addEventListener("click", onClick, true);
  document.addEventListener("submit", onSubmit, true);

  return () => {
    document.removeEventListener("click", onClick, true);
    document.removeEventListener("submit", onSubmit, true);
  };
};
