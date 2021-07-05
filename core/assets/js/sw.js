self.__WB_MANIFEST 

self.addEventListener('push', function(event) {
  event.waitUntil(
    self.registration.showNotification('Push', {
      body: event.data.text(),
    })
  );
});


