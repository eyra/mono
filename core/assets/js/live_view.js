let liveviewId = "";

export const LiveView = {
  mounted() {
    console.log("LiveView mounted");
    liveviewId = this.el.id;

    var initialFieldId = this.el.dataset.initialField
      ? "field_" + this.el.dataset.initialField
      : undefined;

    var savedFieldId = this.loadActiveField();

    // TODO: Fix optional chaining using Webpack >= 5.0.0
    var nextFieldId = initialFieldId ? initialFieldId : savedFieldId;
    this.makeActive(nextFieldId);

    this.el.addEventListener("click", (event) => {
      this.makeActive(undefined);
    });
  },

  updated() {
    var savedFieldId = this.loadActiveField();
    this.makeActive(savedFieldId);
  },

  getActiveFieldKey() {
    return "liveview://" + liveviewId + "/active_field";
  },

  loadActiveField() {
    const fieldKey = this.getActiveFieldKey();
    const activeField = window.localStorage.getItem(fieldKey);
    if (typeof activeField === "string") {
      return activeField;
    }
    return undefined;
  },

  saveActiveField(fieldId) {
    console.info("saveActiveField ", fieldId);
    window.localStorage.setItem(this.getActiveFieldKey(), fieldId);
  },

  makeActive(nextFieldId) {
    this.saveActiveField(nextFieldId);
    var fields = Array.from(document.querySelectorAll('[id^="field-"]'));

    // Show active field
    fields.forEach((field) => {
      var activate = field.id === nextFieldId;
      this.updateField(field, activate);
      if (activate) {
        field.dispatchEvent(new Event("field-activated"));
      }
    });
  },

  updateField(field, activate) {
    var label = field.getElementsByClassName("field-label")[0];
    var input = field.getElementsByClassName("field-input")[0];
    var error = field.getElementsByClassName("field-error")[0];

    if (label) {
      updateElement(label, activate);
    }
    if (input) {
      updateElement(input, activate);
    }
    if (error) {
      updateElement(error, activate);
    }
  },
};

export const Field = {
  mounted() {
    console.log("Field mounted");

    var fieldId = "field-" + this.el.dataset.fieldId;

    var input = this.el.getElementsByClassName("field-input")[0];
    input.addEventListener("click", (event) => {
      event.stopPropagation();
      LiveView.makeActive(fieldId);
      this.pushEvent("active-field", this.el.dataset.fieldId);
    });

    input.addEventListener("focus", (event) => {
      event.stopPropagation();
      LiveView.makeActive(fieldId);
      this.pushEvent("active-field", this.el.dataset.fieldId);
    });

    input.addEventListener("blur", (event) => {
      event.stopPropagation();
      LiveView.makeActive(undefined);
      this.pushEvent("active-field", undefined);
    });
  },
};

function updateElement(element, activate, error) {
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

function customClasses(element, name) {
  return element.getAttribute(name + "-class").split(" ");
}

function updateClassList(element, classes, type) {
  classes.forEach((clazz) => {
    element.classList[type](clazz);
  });
}
