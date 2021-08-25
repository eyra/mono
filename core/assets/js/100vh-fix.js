function setDocHeight() {
    document.documentElement.style.setProperty('--vh', `${window.innerHeight/100}px`);
  };

  window.addEventListener('resize', function () {
    setDocHeight();
   });

  window.addEventListener('orientationchange', function () {
    setDocHeight();
  });

  setDocHeight();
