importScripts("https://cdn.jsdelivr.net/pyodide/v0.19.0/full/pyodide.js");

var data = undefined;

loadPyodide({ indexURL: "https://cdn.jsdelivr.net/pyodide/v0.19.0/full/" }).then((pyodide) => {
  self.pyodide = pyodide;
  return self.pyodide.loadPackage(["micropip", "numpy", "pandas"]);
}).then(() => {
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
    const result = self.pyodide.runPython(`
    def _process_data():
      import json
      import html
      result = process(open("user-data", "rb"))
      data_output = []
      html_output = []
      for data in result:
        html_output.append(f"""<h1 class="text-title4 font-title4 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 mb-6 md:mb-8 lg:mb-10 text-grey1">{html.escape(data['title'])}</h1>""")
        df = data['data_frame']
        html_output.append(df.to_html(classes=["data-donation-extraction-results"], justify="left"))
        data_output.append(df.to_dict())
      return {
        "html": "\\n".join(html_output),
        "data": json.dumps(data_output),
      }
    _process_data()`);
    self.postMessage({ eventType: "result", result: result.toJs({ create_proxies: false, dict_converter: Object.fromEntries }) });
  }
};
