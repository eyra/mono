class Navigation {
  constructor() {
    this.screen =  {navDepth: 0, modalDepth: 0}
  }
  get navDepth() {
    return this.screen.navDepth;
  }

  get modalDepth() {
    return this.screen.modalDepth;
  }

  pushModal() {
    this.screen = Object.assign({}, this.screen, {parent: this.screen, navDepth: 0, modalDepth: this.screen.modalDepth + 1});
    return this.screen
  }

  pushScreen() {
    this.screen = Object.assign({}, this.screen, {parent: this.screen, navDepth: this.screen.navDepth + 1});
    return this.screen
  }

  popModal() {
    let targetModalDepth = Math.max(0, this.screen.modalDepth - 1);
    while (this.screen.modalDepth > targetModalDepth) {
      this.screen = this.screen.parent;
    }
    return this.screen;
  }

  popScreen() {
    let targetNavDepth = Math.max(0, this.screen.navDepth - 1);
    if (this.screen.navDepth > targetNavDepth) {
      this.screen = this.screen.parent
    }
    return this.screen;
  }
}
const nav = new Navigation();

const nativeWrapper = {
  // The native code bridge assumes that handlers have been setup. Seethe docs for more info:
  // https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1537172-add
  //
  // Uncomment each section to enable it.
  pushScreen: ()=> {
    window.webkit.messageHandlers.Push.postMessage({
      type: "regular",
    })
  },
  popScreen: ()=> {
    window.webkit.messageHandlers.Pop.postMessage({
      type: "regular",
    })
  },
  pushModal: () => {
    window.webkit.messageHandlers.Push.postMessage({
      type: "modal",
    })
  },
  popModal: ()=> {
    window.webkit.messageHandlers.Pop.postMessage({
      type: "modal",
    })
  },
  updateScreenInfo: (title)=> {
    window.webkit.messageHandlers.UpdateScreen.postMessage({
      title
    })
  }
}

const updateScreenInfo = ()=>{
  console.log(nav.navDepth);
  const title = `Nav depth ${nav.navDepth}, modal depth: ${nav.modalDepth}`
  document.getElementById("title").innerText = title
  nativeWrapper.updateScreenInfo(title)
}

const pushScreen = ()=>{
  nav.pushScreen();
  nativeWrapper.pushScreen();
  updateScreenInfo()
}

const popScreen = ()=>{
  nativeWrapper.popScreen();
  nav.popScreen();
  updateScreenInfo()
}

const pushModal= () => {
  nav.pushModal();
  nativeWrapper.pushModal();
  updateScreenInfo()
}
const popModal= () => {
  nativeWrapper.popModal();
  nav.popModal();
  updateScreenInfo()
}

updateScreenInfo()

const screenIsPopped= () => {
  nav.popScreen();
  updateScreenInfo()
}

const modalIsPopped= () => {
  nav.popModal();
  updateScreenInfo()
}
