// The server's next render of a face drops this marker; a face that still has
// it after the reply was not re-rendered and still shows the loading feedback.
const CLIENT_LOADING = "data-client-loading";

const activateLoading = (element) => {
  const face = element?.querySelector(".prism-btn");

  face?.classList.add("prism-btn-loading");
  face?.setAttribute(CLIENT_LOADING, "");
  face?.querySelector(":scope > span")?.classList.add("prism-btn-content");
};

export const clearClientLoading = (root) => {
  root.querySelectorAll(`.prism-btn[${CLIENT_LOADING}]`).forEach((face) => {
    face.classList.remove("prism-btn-loading");
    face.removeAttribute(CLIENT_LOADING);
    face.querySelector(":scope > span")?.classList.remove("prism-btn-content");
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
