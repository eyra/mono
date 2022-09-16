export const ProcessingEngine = (function() {
  'use strict';

  /* PUBLIC */

  function registerEventListener(event_listener) {
    _event_listener = event_listener
  }

  function initialise() {
    _worker.postMessage({ eventType: "initialise" })
  }

  function loadScript(script) {
    _worker.postMessage({ eventType: "loadScript", script })
  }

  function firstRunCycle() {
    _worker.postMessage({ eventType: "firstRunCycle" })
  }

  function nextRunCycle(response) {
    _worker.postMessage({ eventType: "nextRunCycle", response })
  }

  function terminate() {
    _worker.terminate()
  }



  /* PRIVATE */

  let _event_listener = (event) => {
    event_string = Object.stringify(event)
    console.log("[ProcessingEngine] No event listener registered for event: ${event_string}")
  }

  const _worker = new Worker("/js/processing_worker.js");
  _worker.onerror = console.log;
  _worker.onmessage = (event) => {
    console.log("[ProcessingEngine] Received event from worker: ", event.data.eventType)
    _event_listener(event)
  }

  /* MODULE INTERFACE */

  return {
    registerEventListener,
    initialise,
    loadScript,
    firstRunCycle,
    nextRunCycle,
    terminate
  }
})();