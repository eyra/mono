self.languagePluginUrl = "https://cdn.jsdelivr.net/pyodide/v0.16.1/full/";
importScripts("https://cdn.jsdelivr.net/pyodide/v0.16.1/full/pyodide.js");

class ChunkedFile {
  constructor(size) {
    this.data = [];
    this.offset = 0;
    this.size = size;
    this.buffer = new Uint8Array(new ArrayBuffer(size));
  }
  tell() {
    return this.offset;
  }
  read(size) {
    if (size === undefined) {
      size = this.size - this.offset;
    }
    if (this.offset >= this.size) {
      return null;
    }
    const readOffset = this.offset;
    this.offset += size;
    return this.buffer.slice(readOffset, readOffset + size);
  }
  seek(offset, whence) {
    switch (whence) {
      case 0:
        this.offset = offset;
        break;
      case 1:
        this.offset += offset;
        break;
      case 2:
        this.offset = this.size + offset;
        break;
    }
  }
  writeChunk(chunk) {
    this.buffer.set(chunk, this.offset);
    this.offset = this.offset + chunk.length;
  }
}

var data = undefined;

languagePluginLoader
  .then(() => {
    return pyodide.loadPackage(["pandas"]);
  })
  .then(() => fetch("/data_extractor/google_semantic_location_history/__init__.py"))
  .then(response => response.text())
  .then((code) => {
    self.pyodide.runPython(`
${code}

class _ChunkedFile:
  def __init__(self, proxy):
    self.proxy = proxy

  def seekable(self):
    return True

  def seek(self, offset, whence=0):
    self.proxy.seek(offset, whence)

  def tell(self):
    return self.proxy.tell()

  def read(self, size=None):
    data = self.proxy.read(size)
    if data:
      return data.tobytes()


def _process_data(data):
  file_data = _ChunkedFile(data)
  result = process(file_data)
  data = []
  html = []
  for df in result.get("data_frames", []):
    html.append(df.to_html())
    data.append(df.to_dict())
  return {
    "summary": result["summary"],
    "html": "\\n".join(html),
    "data": data,
  }
  `);
    self.postMessage({ eventType: "initialized" });
  });

onmessage = (event) => {
  //await languagePluginLoader;
  //await pythonLoading;
  // Don't bother yet with this line, suppose our API is built in such a way:
  const { eventType } = event.data;
  if (eventType === "initData") {
    data = new ChunkedFile(event.data.size);
  } else if (eventType === "data") {
    data.writeChunk(event.data.chunk);
  } else if (eventType === "runPy") {
    const result = self.pyodide.globals._process_data(data);
    self.postMessage({ eventType: "result", result });
  }
};
