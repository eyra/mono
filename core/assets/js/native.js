export const sendNativeSessionEvent = (type) => {
  window.webkit?.messageHandlers?.Native?.postMessage({ type });
};
