import { jsx as _jsx } from "react/jsx-runtime";
import Assembly from "port/dist/framework/assembly";
import Worker from "port/dist/framework/processing/python/worker.js";
import { PyScript } from "port/dist/py_script";
import { isCommandSystemDonate } from "port/dist/framework/types/commands";

import "port/dist/styles.css";

export const Port = {
  mounted() {
    const worker = new Worker();
    const container = document.getElementById(this.el.id);
    const locale = this.el.dataset.locale;
    // const participant = this.el.dataset.participant;
    this.assembly = new Assembly(worker, this);
    this.assembly.visualisationEngine.start(container, locale);
    this.assembly.processingEngine.start(PyScript);
  },

  destroyed() {
    this.assembly.visualisationEngine.destroyed();
  },

  send(command) {
    if (isCommandSystemDonate(command)) {
      this.handleDonation(command);
    } else {
      console.log(
        "[System] received unknown command: " + JSON.stringify(command)
      );
    }
  },

  handleDonation(command) {
    console.log(
      `[System] received donation: ${command.key}=${command.json_string}`
    );
  },
};
