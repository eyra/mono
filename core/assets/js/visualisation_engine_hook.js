import { Tabbar } from "./tabbar"
import { VisualisationEngine } from "./visualisation_engine"

export const VisualisationEngineHook = {
    mounted() {
        console.log("[VisualisationEngineHook] mounted")
        this.hideNextButton("execute")

        const locale = this.el.dataset.locale
        const afterCompletionTab = this.el.dataset.afterCompletionTab

        const hook = this
        const script = this.get_script()
        const prompt_element = this.get_prompt_element()
        const spinner_element = this.get_spinner_element()
        VisualisationEngine.run(script, prompt_element, spinner_element, locale).then((result) => {
            hook.el.querySelector(".no-extraction-data-yet").classList.add("hidden")
            hook.el.querySelector(".donate-form").classList.remove("hidden")
            hook.el.querySelector(".extracted").innerHTML = result.html;
            hook.el.querySelector("input[id='data']").value = result.data;
            Tabbar.show("tab_" + afterCompletionTab, true)
        })
    },
    beforeUpdate() {
        console.log("[VisualisationEngineHook] beforeUpdate")
    },
    updated() {
        console.log("[VisualisationEngineHook] updated")
    },
    destroyed() {
        VisualisationEngine.terminate();
    },
    get_spinner_element() {
        return this.el.querySelector("#spinner")
    },
    get_prompt_element() {
        return this.el.querySelector("#prompt")
    },
    get_script_element() {
        return this.el.getElementsByTagName("code")[0]
    },
    get_script() {
        return this.get_script_element().innerText
    },
    hideNextButton(tabId) {
        this.el.querySelector(`#tabbar-footer-item-${tabId}`).hidden = true
    },
};