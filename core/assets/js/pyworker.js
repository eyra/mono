importScripts("https://cdn.jsdelivr.net/pyodide/v0.19.0/full/pyodide.js");

var data = undefined;

loadPyodide({ indexURL: "https://cdn.jsdelivr.net/pyodide/v0.19.0/full/" }).then((pyodide) => {
  self.pyodide = pyodide;
  return self.pyodide.loadPackage(["micropip", "numpy", "pandas"]);
}).then(() => {
  console.log("test",
    self.pyodide.runPython(`
def _process_data():
  import json
  result = process(open("user-data", "rb"))
  data = []
  html = []
  for df in result.get("data_frames", []):
    html.append(df.to_html())
    data.append(df.to_dict())
  return {
    "html": "\\n".join(html),
    "data": json.dumps(data),
  }
  `));
  self.postMessage({ eventType: "initialized" });
});

let file = undefined

onmessage = (event) => {
  console.log("onmessage", JSON.stringify(event.data))
  const { eventType } = event.data;
  if (eventType === "runPython") {
    console.log("ADFDASF", self.pyodide.runPython(event.data.script))
  } else if (eventType === "initData") {
    file = self.pyodide.FS.open("user-data", "w")
    // data = new ChunkedFile(event.data.size);
  } else if (eventType === "data") {
    self.pyodide.FS.write(file, event.data.chunk, 0, event.data.chunk.length)
    // data.writeChunk(event.data.chunk);
  } else if (eventType === "processData") {
    const proxy = self.pyodide.globals.get("_process_data")
    const resultProxy = proxy()
    const result = resultProxy.toJs({ create_proxies: false, dict_converter: Object.fromEntries });
    [proxy, resultProxy].forEach(p => p.destroy())
    self.postMessage({ eventType: "result", result });
  }
};
