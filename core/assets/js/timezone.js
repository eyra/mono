export const TimeZone = {
  mounted() {
    timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    console.log("TimeZone", timezone);
    this.pushEventTo(".timezone", "timezone", timezone);
  },
  sendToServer() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    console.log("TIMEZONE", timezone);

    let csrfToken = document
      .querySelector("meta[name='csrf-token']")
      .getAttribute("content");

    if (typeof window.localStorage != "undefined") {
      try {
        // if we sent the timezone already or the timezone changed since last time we sent
        if (!localStorage["timezone"] || localStorage["timezone"] != timezone) {
          var xhr = new XMLHttpRequest();
          xhr.open("POST", "/api/timezone", true);
          xhr.setRequestHeader("Content-Type", "application/json");
          xhr.setRequestHeader("x-csrf-token", csrfToken);
          xhr.onreadystatechange = function () {
            if (
              this.readyState === XMLHttpRequest.DONE &&
              this.status === 200
            ) {
              localStorage["timezone"] = timezone;
            }
          };
          xhr.send(`{"timezone": "${timezone}"}`);
        }
      } catch (e) {}
    }
  },
};
