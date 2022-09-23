export class ProcessingEngine {
  constructor(workerFile) {
    this.eventListener = (event) => {
      event_string = Object.stringify(event);
      console.log(
        "[ProcessingEngine] No event listener registered for event: ",
        event_string
      );
    };

    this.worker = new Worker(workerFile);
    this.worker.onerror = console.log;
    this.worker.onmessage = (event) => {
      console.log(
        "[ProcessingEngine] Received event from worker: ",
        event.data.eventType
      );
      this.eventListener(event);
    };
  }

  start() {
    this.worker.postMessage({ eventType: "initialise" });
  }

  loadScript(script) {
    this.worker.postMessage({ eventType: "loadScript", script });
  }

  firstRunCycle() {
    this.worker.postMessage({ eventType: "firstRunCycle" });
  }

  nextRunCycle(response) {
    this.worker.postMessage({ eventType: "nextRunCycle", response });
  }

  terminate() {
    this.worker.terminate();
  }
}
