export const ResetScroll = {
  mounted() {
    this.el.scrollIntoView({ block: "start" });
  },
};
