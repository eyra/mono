import { Tabbar } from "./tabbar"

export const PythonUploader = {
    nextButtonSelector: "#tabbar-footer-item-file_selection",

    destroyed() {
        this.worker && this.worker.terminate();
    },
    mounted() {
        console.log("PythonUploader mounted")
        const uploader = this;

        // First hide the next button (requires selected file)
        this.el.querySelector(this.nextButtonSelector).hidden = true

        // Hook up the process button to the worker
        const fileInput = this.el.querySelector("input[type=file]")
        fileInput.addEventListener("change", () => {
            this.el.querySelector(this.nextButtonSelector).hidden = false
        })
        this.el.querySelector("#tab_data_extraction").addEventListener("tab-activated", () => {
            const script = this.el.getElementsByTagName("code")[0].innerText
            uploader.process(script).then((result) => {
                uploader.result = result;
                uploader.el.querySelector(".extracted").innerHTML = result.html;
                uploader.el.querySelector("input[name='data']").value = result.data;
                console.log("done", result)
                Tabbar.show("tab_" + this.el.dataset.afterCompletionTab, true)
            })
        })
    },
    process(script) {
        console.log("PPPPPPPPPPPPPPPP")
        return new Promise((resolve) => {
            // Initialize the Python worker
            const worker = new Worker("/js/pyworker.js");
            worker.onerror = console.log;
            worker.onmessage = (event) => {
                const { eventType } = event.data;
                if (eventType === "initialized") {
                    worker.postMessage({ eventType: "runPython", script })
                    this.sendDataToWorker(worker)
                }
                else if (eventType === "result") {
                    worker.terminate()
                    resolve(event.data.result)
                }
            }
        })
    },
    sendDataToWorker(worker) {
        const fileInput = this.el.querySelector("input[type=file]")
        const file = fileInput.files[0];
        const reader = file.stream().getReader();
        const sendToWorker = ({ done, value }) => {
            if (done) {
                worker.postMessage({ eventType: "processData" });
                return;
            }
            worker.postMessage({ eventType: "data", chunk: value });
            reader.read().then(sendToWorker);
        };
        worker.postMessage({ eventType: "initData", size: file.size });
        reader.read().then(sendToWorker);
    }
}