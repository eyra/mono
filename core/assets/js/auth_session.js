import { sendNativeSessionEvent } from "./native";

export const installAuthSessionHandlers = ({ csrfToken }) => {
  const sessionEvent = new URLSearchParams(window.location.search).get(
    "session_event"
  );

  if (sessionEvent === "logged_out") {
    const url = new URL(window.location);
    url.searchParams.delete("session_event");
    window.history.replaceState({}, "", url);
    sendNativeSessionEvent(sessionEvent);
  }

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
