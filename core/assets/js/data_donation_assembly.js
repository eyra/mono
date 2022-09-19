import { VisualisationEngine } from "./visualisation_engine";
import { VisualisationFactory } from "./visualisation_factory";
import { ProcessingEngine } from "./processing_engine";

export class DataDonationAssembly {
  constructor() {
    this.visualisationFactory = new VisualisationFactory();
    this.processingEngine = new ProcessingEngine("/js/processing_worker.js");
    this.visualisationEngine = new VisualisationEngine(
      this.visualisationFactory,
      this.processingEngine
    );

    this.processingEngine.eventListener = this.visualisationEngine.onEvent;
  }
}
