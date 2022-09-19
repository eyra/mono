import { ElementRef } from "./element_ref";

export class VisualisationEngine {
  constructor(factory, processingEngine) {
    this.factory = factory;
    this.processingEngine = processingEngine;
  }

  run(script, promptElement, spinnerElement, locale) {
    return new Promise((resolve) => {
      const flowController = createFlowController(
        script,
        this.wrap(promptElement),
        this.wrap(spinnerElement),
        locale,
        resolve
      );
      this.processingEngine.registerEventListener(flowController);
      this.processingEngine.initialise();
    });
  }

  createFlowController(
    script,
    promptElement,
    spinnerElement,
    locale,
    finishFlow
  ) {
    return function (event) {
      const { eventType } = event.data;
      console.log("[VisualisationEngine] received eventType: ", eventType);
      switch (eventType) {
        case "initialiseDone":
          console.log("[VisualisationEngine] received: initialiseDone");
          this.processingEngine.loadScript(script);
          break;

        case "loadScriptDone":
          console.log("[VisualisationEngine] Received: loadScriptDone");
          this.processingEngine.firstRunCycle();
          break;

        case "runCycleDone":
          console.log("[VisualisationEngine] received: cmd", event.data.cmd);
          this.handleRunCycle(
            event.data.cmd,
            promptElement,
            spinnerElement,
            locale,
            finishFlow
          );
          break;
        default:
          console.log(
            "[VisualisationEngine] received unsupported flow event: ",
            eventType
          );
      }
    };
  }

  terminate() {
    this.processingEngine.terminate();
  }

  /* PRIVATE */

  handleRunCycle(data, promptElement, spinnerElement, locale, finishFlow) {
    const { cmd } = data;
    switch (cmd) {
      case "result":
        this.finishFlow(data.result);
        break;
      case "prompt":
        promptElement.show();
        spinnerElement.hide();
        this.handlePrompt(data.prompt, promptElement, locale).then(
          (userInput) => {
            promptElement.hide();
            spinnerElement.show();
            this.processingEngine.nextRunCycle({
              prompt: data.prompt,
              userInput: userInput,
            });
          }
        );
        break;
      default:
        console.log(
          "[VisualisationEngine] Received unsupported processing cmd: ",
          cmd
        );
    }
  }

  handlePrompt(promptData, promptElement, locale) {
    return new Promise((resolve) => {
      const prompt = this.factory.createComponent(promptData, locale);
      prompt.render(promptElement);
      prompt.activate(promptElement, resolve);
    });
  }

  wrap(element) {
    return new ElementRef(element);
  }
}
