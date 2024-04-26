export const TimeZone = {
  mounted() {
    timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    console.log("TimeZone", timezone);
    this.pushEventTo(".timezone", "timezone", timezone);
  },
  sendToServer() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    console.log("[TimeZone]", timezone);

    let csrfToken = document
      .querySelector("meta[name='csrf-token']")
      .getAttribute("content");

    if (typeof window.localStorage != "undefined") {
      try {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "/api/timezone", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("x-csrf-token", csrfToken);
        xhr.onreadystatechange = function () {
          console.log(
            "[TimeZone] POST onreadystatechange",
            this.status,
            this.readyState
          );
        };
        xhr.send(`{"timezone": "${timezone}"}`);
      } catch (e) {
        console.log("[TimeZone] Error while sending timezone to server", e);
      }
    }
  },
};
