const loadingIndicator = document.getElementById("loading-indicator");
const processButton = document.getElementById("process");
const fileInput = document.getElementById("fileItem");
const resultElement = document.getElementById("results");
const summaryElement = document.getElementById("summary");

const pyWorker = new Worker("/js/pyworker.js");
pyWorker.onerror = console.log;
pyWorker.onmessage = (event) => {
  const { eventType } = event.data;
  if (eventType === "result") {
    setControlsDisabled(false);
    summaryElement.textContent = event.data.result.summary;
    resultElement.style.display = "block";
    console.log(event.data.result);
  }
  else if (eventType === "initialized") {
    const script = document.getElementById("python-script").innerText
    pyWorker.postMessage({eventType: "runPython", script })
    loadingIndicator.hidden = true;
    fileInput.disabled = false;
  }
};

const setControlsDisabled = (disabled) => {
  fileInput.disabled = disabled;
  processButton.disabled = disabled;
};

window.toggleProcessButton = () => {
  const file = fileInput.files[0];
  processButton.disabled = file === undefined;
};

window.process = () => {
  setControlsDisabled(true);
  resultElement.style.display = "none";

  const file = fileInput.files[0];
  const reader = file.stream().getReader();
  const sendToWorker = ({ done, value }) => {
    if (done) {
      pyWorker.postMessage({ eventType: "processData" });
      return;
    }
    pyWorker.postMessage({ eventType: "data", chunk: value });
    reader.read().then(sendToWorker);
  };
  pyWorker.postMessage({ eventType: "initData", size: file.size });
  reader.read().then(sendToWorker);
};
