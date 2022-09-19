let pyScript = undefined;

onmessage = (event) => {
  const { eventType } = event.data;
  switch (eventType) {
    case "initialise":
      initialise().then(() => {
        self.postMessage({ eventType: "initialiseDone" });
      });
      break;

    case "loadScript":
      loadScript(event.data.script);
      self.postMessage({ eventType: "loadScriptDone" });
      break;

    case "firstRunCycle":
      pyScript = self.pyodide.runPython(pyWorker());
      runCycle(null);
      break;

    case "nextRunCycle":
      const { response } = event.data;
      unwrap(response).then((userInput) => {
        runCycle(userInput);
      });
      break;

    default:
      console.log("[ProcessingWorker] Received unsupported event: ", eventType);
  }
};

function runCycle(userInput) {
  cmd = pyScript.send(userInput);
  self.postMessage({
    eventType: "runCycleDone",
    cmd: cmd.toJs({
      create_proxies: false,
      dict_converter: Object.fromEntries,
    }),
  });
}

function unwrap(response) {
  return new Promise((resolve) => {
    switch (response.prompt.type) {
      case "file":
        copyFileToPyFS(response.userInput, resolve);
        break;

      default:
        resolve(response.userInput);
    }
  });
}

function copyFileToPyFS(file, resolve) {
  const reader = file.stream().getReader();
  const pyFile = self.pyodide.FS.open(file.name, "w");

  const writeToPyFS = ({ done, value }) => {
    if (done) {
      resolve(file.name);
    } else {
      self.pyodide.FS.write(pyFile, value, 0, value.length);
      reader.read().then(writeToPyFS);
    }
  };
  reader.read().then(writeToPyFS);
}

function initialise() {
  importScripts("https://cdn.jsdelivr.net/pyodide/v0.21.2/full/pyodide.js");

  return loadPyodide({
    indexURL: "https://cdn.jsdelivr.net/pyodide/v0.21.2/full/",
  }).then((pyodide) => {
    self.pyodide = pyodide;
    return self.pyodide.loadPackage(["micropip", "numpy", "pandas"]);
  });
}

function loadScript(script) {
  console.log("[ProcessingWorker] loadScript");
  self.pyodide.runPython(script);
}

function pyWorker() {
  return `
  from collections.abc import Generator
  import json
  import html
  import pandas as pd

  class ScriptWrapper(Generator):
    def __init__(self, script):
        self.script = script
    def send(self, data):
        if data == None:
          return self.script.send(None)
        else:
          response = self.script.send(data)
          if response["cmd"] == "result":
            response["result"] = self.translate_result(response["result"])
          return response
    def throw(self, type=None, value=None, traceback=None):
        raise StopIteration
    def translate_result(self, result):
      data_output = []
      html_output = []
      for data in result:
        html_output.append(f"""<h1 class="text-title4 font-title4 sm:text-title3 sm:font-title3 mt-12 mb-6 text-grey1">{html.escape(data["title"])}</h1>""")
        df = data["data_frame"]
        html_output.append(df.to_html(classes=["data-donation-extraction-results"], justify="left"))
        data_output.append({"id": data["id"], "data_frame": df.to_json()})
      return {
        "html": "\\n".join(html_output),
        "data": json.dumps(data_output),
      }
  script = process()
  ScriptWrapper(script)
  `;
}
