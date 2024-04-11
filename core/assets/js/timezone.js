export const TimeZone = {
  mounted() {
    timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    console.log("TimeZone", timezone);
    this.pushEventTo(".timezone", "timezone", timezone);
  },
};
