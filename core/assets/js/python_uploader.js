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
        this.el.querySelector(".extract-data-button").addEventListener("click", () => {
            this.el.querySelector(".select-file").classList.add("hidden")
            this.el.querySelector(".extract-data").classList.add("hidden")
            this.el.querySelector(".data-extraction").classList.remove("hidden")
            const script = this.el.getElementsByTagName("code")[0].innerText
            uploader.process(script).then((result) => {
                uploader.result = result;
                uploader.el.querySelector(".no-extraction-data-yet").classList.add("hidden")
                uploader.el.querySelector(".donate-form").classList.remove("hidden")
                uploader.el.querySelector(".extracted").innerHTML = result.html;
                uploader.el.querySelector("input[name='data']").value = result.data;
                console.log("done", result)
                Tabbar.show("tab_" + this.el.dataset.afterCompletionTab, true)
                this.el.querySelector(".extract-data").classList.remove("hidden")
                this.el.querySelector(".data-extraction").classList.add("hidden")
            })
        });

        // Hook up the process button to the worker
        const fileInput = this.el.querySelector("input[type=file]")
        fileInput.addEventListener("change", () => {
            console.log("File input changed")
            this.el.querySelector(".select-file").classList.add("hidden");
            this.el.querySelector(".extract-data").classList.remove("hidden");
            const filenameInfo = this.el.querySelector(".selected-filename");
            filenameInfo.innerText = fileInput.files[0].name;
            filenameInfo.classList.remove("hidden")
        })


        this.el.querySelector(".reset-button").addEventListener("click", () => {
            // clear current selected file
            const fileInput = this.el.querySelector("input[type=file]")
            fileInput.type= "text"
            fileInput.type= "file"

            // show select file panel
            this.el.querySelector(".select-file").classList.remove("hidden")
            this.el.querySelector(".extract-data").classList.add("hidden")
        });
    },
    process(script) {
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