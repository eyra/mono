export const Toggle = {
    mounted() {
        console.log("Show mounted ", this.el)
        this.targetId = this.el.getAttribute("target")
        this.target = document.getElementById(this.targetId);
        this.target.style.display = "none"

        this.el.addEventListener("click", (event)=>{
            event.stopPropagation()
            if (this.target.style.display !== "block") {
                this.onshow()
            } else {
                this.onhide()
            }
        })

        this.onshow = () => {
            console.log("onshow", this.target.style.display)
            this.target.style.display = "block"
            this.startListening()
        }

        this.onhide = () => {
            console.log("onhide")
            this.target.style.display = "none"
            this.stopListening()
        }

        this.startListening = () => {
            document.addEventListener('click', this.onhide)
            document.addEventListener('focus', this.onhide, true)
        }

        this.stopListening = () => {
            document.removeEventListener('click', this.onhide)
            document.removeEventListener('focus', this.onhide)
        }
    }
  }
