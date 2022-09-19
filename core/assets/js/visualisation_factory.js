import { FileInput } from "./file_input";
import { RadioInput } from "./radio_input";

export class VisualisationFactory {
  constructor() {
    this.mapping = {
      file: FileInput,
      radio: RadioInput,
    };
  }

  createComponent(data, locale) {
    const { type } = data;

    if (mapping[type]) {
      const componentData = data[type];
      const componentClass = this.mapping[type];
      return new componentClass(componentData, locale);
    } else {
      console.log("[VisualisationFactory] Received unsupported prompt: ", type);
      return null;
    }
  }
}
