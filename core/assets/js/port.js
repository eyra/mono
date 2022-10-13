import { jsx as _jsx } from "react/jsx-runtime";
import { Assembly } from "port/dist/framework/assembly";
import { PyScript } from "port/dist/py_script";

import Worker from "port/dist/framework/processing/python/worker.js";

import "port/dist/styles.css";

export const Port = {
  mounted() {
    const worker = new Worker();
    const container = document.getElementById(this.el.id);
    this.visualisationEngine = Assembly(worker);
    this.visualisationEngine.start(PyScript, container, "en").then(
      () => {},
      () => {}
    );
  },

  destroyed() {
    this.assembly.visualisationEngine.destroyed();
  },
};
