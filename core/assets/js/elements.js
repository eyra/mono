export function activateElement(element, activate) {
  console.log("Activate element");
  if (!element) {
    return console.warn("Unknown element");
  }

  var idle_classes = customClasses(element, "idle");
  var active_classes = customClasses(element, "active");

  if (activate) {
    updateClassList(element, idle_classes, "remove");
    updateClassList(element, active_classes, "add");
  } else {
    updateClassList(element, active_classes, "remove");
    updateClassList(element, idle_classes, "add");
  }
}

export function customClasses(element, name) {
  return element.getAttribute(name + "-class").split(" ");
}

export function updateClassList(element, classes, type) {
  classes.forEach((clazz) => {
    element.classList[type](clazz);
  });
}
