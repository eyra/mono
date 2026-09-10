export const installAuthSessionHandlers = ({ csrfToken }) => {
  window.addEventListener("phx:auth:signout", ({ detail: { url } }) => {
    const form = document.createElement("form");
    form.method = "post";
    form.action = url;

    for (const [name, value] of Object.entries({
      _method: "delete",
      _csrf_token: csrfToken,
    })) {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = name;
      input.value = value;
      form.appendChild(input);
    }

    document.body.appendChild(form);
    form.submit();
  });
};
