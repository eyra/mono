function setDocHeight() {
  document.documentElement.style.setProperty('--vh', `${window.innerHeight/100}px`);
};

["resize", "orientationchange", "DOMContentLoaded"].forEach((eventName)=>{
  window.addEventListener(eventName, setDocHeight);
});
