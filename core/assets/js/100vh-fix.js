function setDocHeight() {
    console.log(`Window inner height: ${window.innerHeight}`);
    document.documentElement.style.setProperty('--vh', `${window.innerHeight/100}px`);
  };

  window.addEventListener('resize', function () {
    setDocHeight();
   });

  window.addEventListener('orientationchange', function () {
    setDocHeight();
  });

  setDocHeight();
