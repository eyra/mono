import _ from 'lodash'

let resizeHandler

export const ViewportResize = {

  mounted () {
    // Direct push of current window size to properly update view
    this.pushResizeEvent()

    window.addEventListener('resize', (event) => {
      this.pushResizeEvent()
    })
  },

  pushResizeEvent () {
    console.log("pushResizeEvent")
    this.pushEvent('viewport_resize', {
      width: window.innerWidth,
      height: window.innerHeight
    })
  },

  turbolinksDisconnected () {
    window.removeEventListener('resize', resizeHandler)
  }
}