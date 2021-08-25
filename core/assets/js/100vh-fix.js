function setDocHeight() {
    document.documentElement.style.setProperty('--vh', `${window.innerHeight/100}px`);
  };

  window.addEventListener('resize', setDocHeight);

  window.addEventListener('orientationchange', setDocHeight);

  setDocHeight();
