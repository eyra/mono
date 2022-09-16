import { VisualisationFactory } from "./visualisation_factory"
import { ProcessingEngine } from "./processing_engine"

export const VisualisationEngine = (function() {
    'use strict';

    /* PUBLIC */

    function run(script, promptElement, spinnerElement, locale) {
        return new Promise((resolve) => {
            const flowController = createFlowController(script, wrap(promptElement), wrap(spinnerElement), locale, resolve)
            ProcessingEngine.registerEventListener(flowController)
            ProcessingEngine.initialise()
        })
    }

    function createFlowController(script, promptElement, spinnerElement, locale, finishFlow) {
        return function (event) {
            const { eventType } = event.data;
            console.log("[VisualisationEngine] received eventType: ", eventType)
            switch (eventType) {
                case "initialiseDone":
                    console.log("[VisualisationEngine] received: initialiseDone")
                    ProcessingEngine.loadScript(script)
                    break;

                case "loadScriptDone":
                    console.log("[VisualisationEngine] Received: loadScriptDone")
                    ProcessingEngine.firstRunCycle()
                    break;

                case "runCycleDone":
                    console.log("[VisualisationEngine] received: cmd", event.data.cmd)
                    handleRunCycle(event.data.cmd, promptElement, spinnerElement, locale, finishFlow)
                    break;
                default:
                    console.log("[VisualisationEngine] received unsupported flow event: ", eventType)
            }
        }
    }

    function terminate() {
        ProcessingEngine.terminate();
    }

    /* PRIVATE */

    function handleRunCycle(data, promptElement, spinnerElement, locale, finishFlow) {
        const { cmd } = data;
        switch (cmd) {
            case "result":
                finishFlow(data.result)
                break;
            case "prompt":
                promptElement.show()
                spinnerElement.hide()
                handlePrompt(data.prompt, promptElement, locale).then((userInput) => {
                    promptElement.hide()
                    spinnerElement.show()
                    ProcessingEngine.nextRunCycle({"prompt": data.prompt, "userInput": userInput} )
                })
                break;
            default:
                console.log("[VisualisationEngine] Received unsupported processing cmd: ", cmd)
        }
    }

    function handlePrompt(promptData, promptElement, locale) {
        return new Promise((resolve) => {
            const prompt = VisualisationFactory.createComponent(promptData, locale)
            prompt.render(promptElement)
            prompt.activate(promptElement, resolve)
        })
    }

    function wrap(element) {
        if (element === null) {
            throw `Can not wrap element: ${element}`;
        }

        return {
            el: element,
            onClick(handle) {
                this.el.addEventListener("click", (_event) => {
                    handle()
                })
            },
            onChange(handle) {
                this.el.addEventListener("change", (_event) => {
                    handle()
                })
            },
            selectedFile() {
                return this.el.files[0]
            },
            reset() {
                this.el.type= "text"
                this.el.type= "file"
            },
            click() {
                this.el.click()
            },
            hide() {
                if (!this.el.classList.contains("hidden")) {
                    this.el.classList.add("hidden")
                }
            },
            show() {
                this.el.classList.remove("hidden")
            },
            child(childId) {
                const child = this.el.querySelector(`#${childId}`)
                if (child === null) {
                    throw `Child not found: ${childId}`;
                } else {
                    return wrap(child)
                }
            },
            childs(className) {
                let result = []
                const elements = this.el.getElementsByClassName(className)
                const childs = Array.from(elements)
                for (let child of childs) {
                    result.push(wrap(child))
                }
                return result
            }
        }
    }

    /* MODULE INTERFACE */

    return {
        run: run,
        terminate: terminate
    }
})();