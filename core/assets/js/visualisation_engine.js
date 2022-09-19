import { ElementRef } from "./element_ref";

export class VisualisationEngine {
  constructor(factory, processingEngine) {
    this.factory = factory;
    this.processingEngine = processingEngine;
    this.onEvent = (event) => {
      this.handleEvent(event);
    };
  }

  start(script, promptElement, spinnerElement, locale) {
    this.script = script;
    this.promptElement = this.wrap(promptElement);
    this.spinnerElement = this.wrap(spinnerElement);
    this.locale = locale;
    return new Promise((resolve) => {
      this.finishFlow = resolve;
    });
  }

  handleEvent(event) {
    console.log("this", this);

    const { eventType } = event.data;
    console.log("[VisualisationEngine] received eventType: ", eventType);
    switch (eventType) {
      case "initialiseDone":
        console.log("[VisualisationEngine] received: initialiseDone");
        this.processingEngine.loadScript(this.script);
        break;

      case "loadScriptDone":
        console.log("[VisualisationEngine] Received: loadScriptDone");
        this.processingEngine.firstRunCycle();
        break;

      case "runCycleDone":
        console.log("[VisualisationEngine] received: cmd", event.data.cmd);
        this.handleRunCycle(event.data.cmd);
        break;
      default:
        console.log(
          "[VisualisationEngine] received unsupported flow event: ",
          eventType
        );
    }
  }

  terminate() {
    this.processingEngine.terminate();
  }

  /* PRIVATE */

  handleRunCycle(data) {
    const { cmd } = data;
    switch (cmd) {
      case "result":
        this.finishFlow(data.result);
        break;
      case "prompt":
        this.promptElement.show();
        this.spinnerElement.hide();
        this.handlePrompt(data.prompt).then((userInput) => {
          this.promptElement.hide();
          this.spinnerElement.show();
          this.processingEngine.nextRunCycle({
            prompt: data.prompt,
            userInput: userInput,
          });
        });
        break;
      default:
        console.log(
          "[VisualisationEngine] Received unsupported processing cmd: ",
          cmd
        );
    }
  }

  handlePrompt(promptData) {
    return new Promise((resolve) => {
      const prompt = this.factory.createComponent(promptData, this.locale);
      prompt.render(this.promptElement);
      prompt.activate(this.promptElement, resolve);
    });
  }

  wrap(element) {
    return new ElementRef(element);
  }
}
