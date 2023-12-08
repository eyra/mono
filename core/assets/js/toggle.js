export const Toggle = {
  mounted() {
    this.targetId = this.el.getAttribute("target");
    this.target = document.getElementById(this.targetId);
    this.target.style.display = "none";

    document.addEventListener("click", (event) => {
      if (event.target === this.el) {
        if (this.target.style.display !== "block") {
          this.target.style.display = "block";
        } else {
          this.target.style.display = "none";
        }
      } else if (event.target === this.target) {
        // nothing
      } else {
        this.target.style.display = "none";
      }
    });
  },
};
