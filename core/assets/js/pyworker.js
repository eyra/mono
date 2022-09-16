importScripts("https://cdn.jsdelivr.net/pyodide/v0.21.2/full/pyodide.js");

var data = undefined;

loadPyodide({ indexURL: "https://cdn.jsdelivr.net/pyodide/v0.21.2/full/" }).then((pyodide) => {
  self.pyodide = pyodide;
  return self.pyodide.loadPackage(["micropip", "numpy", "pandas"]);
}).then(() => {
  self.postMessage({ eventType: "initialized" });
});

let file = undefined
var filename = undefined

onmessage = (event) => {
  const { eventType } = event.data;
  if (eventType === "loadScript") {
    self.pyodide.runPython(event.data.script)
  } else if (eventType === "initData") {
    filename = event.data.filename
    file = self.pyodide.FS.open(filename, "w")
  } else if (eventType === "data") {
    self.pyodide.FS.write(file, event.data.chunk, 0, event.data.chunk.length)
  } else if (eventType === "processData") {
    const result = self.pyodide.runPython(`
    def _process_data():
      import json
      import html
      import pandas as pd

      result = process("${filename}")

      if not result:
        data_frame = pd.DataFrame()
        data_frame["Messages"] = pd.Series(["Unfortunately, no data could be extracted from the selected file."], name="Messages")
        result = [{"id": "important_feedback", "title": "Important feedback", "data_frame": data_frame}]

      data_output = []
      html_output = []
      for data in result:
        html_output.append(f"""<h1 class="text-title4 font-title4 sm:text-title3 sm:font-title3 mt-12 mb-6 text-grey1">{html.escape(data['title'])}</h1>""")
        df = data['data_frame']
        html_output.append(df.to_html(classes=["data-donation-extraction-results"], justify="left"))
        data_output.append({"id": data["id"], "data_frame": df.to_json()})

      return {
        "html": "\\n".join(html_output),
        "data": json.dumps(data_output),
      }
    _process_data()`);
    self.postMessage({ eventType: "result", result: result.toJs({ create_proxies: false, dict_converter: Object.fromEntries }) });
  } else if (eventType === "run_cycle") {

    var prompt = undefined

    if (generator == undefined) {
      generator = self.pyodide.runPython(`
        return process()
      `);
      prompt = generator.__next__()
    } else {
      prompt = generator.send(event.data)
    }

    self.postMessage({ eventType: "prompt", result: prompt.toJs({ create_proxies: false, dict_converter: Object.fromEntries }) });
  }
};
