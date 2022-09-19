import { Tabbar } from "./tabbar";
import { DataDonationAssembly } from "./data_donation_assembly";

const assembly = new DataDonationAssembly();

export const DataDonationHook = {
  mounted() {
    console.log("[DataDonationHook] mounted");
    this.hideNextButton("execute");

    const locale = this.el.dataset.locale;
    const afterCompletionTab = this.el.dataset.afterCompletionTab;

    const hook = this;
    const script = this.get_script();
    const prompt_element = this.get_prompt_element();
    const spinner_element = this.get_spinner_element();

    assembly.visualisationEngine
      .start(script, prompt_element, spinner_element, locale)
      .then((result) => {
        hook.el
          .querySelector(".no-extraction-data-yet")
          .classList.add("hidden");
        hook.el.querySelector(".donate-form").classList.remove("hidden");
        hook.el.querySelector(".extracted").innerHTML = result.html;
        hook.el.querySelector("input[id='data']").value = result.data;
        Tabbar.show("tab_" + afterCompletionTab, true);
      });

    assembly.processingEngine.start();
  },
  beforeUpdate() {
    console.log("[DataDonationHook] beforeUpdate");
  },
  updated() {
    console.log("[DataDonationHook] updated");
  },
  destroyed() {
    assembly.visualisationEngine.terminate();
  },
  get_spinner_element() {
    return this.el.querySelector("#spinner");
  },
  get_prompt_element() {
    return this.el.querySelector("#prompt");
  },
  get_script_element() {
    return this.el.getElementsByTagName("code")[0];
  },
  get_script() {
    return this.get_script_element().innerText;
  },
  hideNextButton(tabId) {
    this.el.querySelector(`#tabbar-footer-item-${tabId}`).hidden = true;
  },
};
