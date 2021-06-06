export const registerAPNSDeviceToken = (deviceToken) => {
    fetch("/api/apns-token", {
        method: "post",
        headers: {
          "Content-type": "application/json",
        },
        body: JSON.stringify({ device_token: deviceToken }),
    })
}
