const activateLoading = (element) => {
  const face = element?.querySelector(".prism-btn");

  face?.classList.add("prism-btn-loading");
  face?.querySelector(":scope > span")?.classList.add("prism-btn-content");
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
