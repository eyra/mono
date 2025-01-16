const STATIC_CLASS_ATTR = "__eyra_field_static_class";
const HAS_ERRORS_ATTR = "__eyra_field_has_errors";
const ACTIVE_COLOR_ATTR = "__eyra_field_active_color";

const FIELD_LABEL_TYPE = "field-label";
const FIELD_INPUT_TYPE = "field-input";
const FIELD_ERROR_TYPE = "field-error";

const DATA_SHOW_ERRORS = "data-show-errors";

const LABEL_IDLE = "text-grey1";
const LABEL_ERROR = "text-warning";

const INPUT_IDLE = "border-grey3";
const INPUT_ERROR = "border-warning";

const HIDDEN = "hidden";

export const LiveContent = {
  mounted() {
    console.log("[LiveContent] mounted", this.el);
    console.log(
      "[LiveContent] DATA_SHOW_ERRORS",
      this.el.getAttribute(DATA_SHOW_ERRORS)
    );
    this.showErrors = this.el.getAttribute(DATA_SHOW_ERRORS) != null;
    this.activeField = undefined;

    this.el.addEventListener("click", (event) => {
      this.activeField = undefined;
      this.applyActiveField();
    });

    this.el.addEventListener("field-activated", (event) => {
      event.stopPropagation();
      this.activeField = event.target.dataset.fieldId;
      this.applyActiveField();
    });

    this.el.addEventListener("field-deactivated", (event) => {
      event.stopPropagation();
      if (this.activeField == event.target.id) {
        this.activeField = undefined;
        this.applyActiveField();
      }
    });

    this.applyErrors();
    this.applyActiveField();
  },
  updated() {
    console.log("[LiveContent] updated", this.el);
    console.log(
      "[LiveContent] DATA_SHOW_ERRORS",
      this.el.getAttribute(DATA_SHOW_ERRORS)
    );
    this.showErrors = this.el.getAttribute(DATA_SHOW_ERRORS) != null;
    this.applyErrors();
    this.applyActiveField();
  },
  onBeforeElUpdated(from, to) {
    const field_id = from.getAttribute("__eyra_field_id");

    if (field_id != null) {
      to.classList = from.classList;
    }
  },
  applyErrors() {
    const fieldErrors = Array.from(
      this.el.querySelectorAll(`.${FIELD_ERROR_TYPE}`)
    );

    console.log("[LiveContent] fieldErrors", fieldErrors);

    console.log("[LiveContent] this.showErrors", this.showErrors);

    if (this.showErrors) {
      fieldErrors.forEach((fieldError) => {
        fieldError.classList.remove(HIDDEN);
        console.log("[LiveContent] fieldError.classList", fieldError.classList);
      });
    } else {
      fieldErrors.forEach((fieldError) => fieldError.classList.add(HIDDEN));
    }
  },
  updateFieldItem(fieldItem, activate) {
    const hasErrors = fieldItem.getAttribute(HAS_ERRORS_ATTR) != null;

    if (fieldItem.classList.contains(FIELD_LABEL_TYPE)) {
      this.updateFieldLabel(fieldItem, activate, hasErrors);
    } else if (fieldItem.classList.contains(FIELD_INPUT_TYPE)) {
      this.updateFieldInput(fieldItem, activate, hasErrors);
    }
  },
  applyActiveField() {
    var fields = Array.from(this.el.querySelectorAll('[id^="field-"]'));
    fields.forEach((field) => {
      var activate = field.dataset.fieldId === this.activeField;
      this.updateField(field, activate);
    });
  },
  updateField(field, activate) {
    const label = field.getElementsByClassName(FIELD_LABEL_TYPE)[0];
    const input = field.getElementsByClassName(FIELD_INPUT_TYPE)[0];

    const hasErrors = field.getElementsByClassName(FIELD_ERROR_TYPE)[0] != null;

    if (label) {
      this.updateFieldLabel(label, activate, hasErrors);
    }

    if (input) {
      this.updateFieldInput(input, activate, hasErrors);
    }
  },
  updateFieldLabel(label, activate, hasErrors) {
    this.updateFieldItemClass(
      label,
      activate,
      hasErrors,
      LABEL_IDLE,
      LABEL_ERROR
    );
  },
  updateFieldInput(input, activate, hasErrors) {
    this.updateFieldItemClass(
      input,
      activate,
      hasErrors,
      INPUT_IDLE,
      INPUT_ERROR
    );
  },
  updateFieldItemClass(
    fieldItem,
    activate,
    hasErrors,
    idle_class,
    error_class
  ) {
    var dynamic_class = idle_class;
    if (activate) {
      dynamic_class = fieldItem.getAttribute(ACTIVE_COLOR_ATTR);
    } else if (this.showErrors && hasErrors) {
      dynamic_class = error_class;
    }
    const static_class = fieldItem.getAttribute(STATIC_CLASS_ATTR);
    fieldItem.setAttribute("class", static_class + " " + dynamic_class);
  },
};

export const LiveField = {
  mounted() {
    console.log("[LiveField] mounted");
    const input = this.el.getElementsByClassName(FIELD_INPUT_TYPE)[0];

    if (input) {
      input.addEventListener("click", (event) => {
        event.stopPropagation();
        this.activate();
      });

      input.addEventListener("focus", (event) => {
        event.stopPropagation();
        this.activate();
      });

      input.addEventListener("blur", (event) => {
        event.stopPropagation();
        this.deactivate();
      });
    }
  },
  activate() {
    this.el.dispatchEvent(new Event("field-activated", { bubbles: true }));
  },
  deactivate() {
    this.el.dispatchEvent(new Event("field-deactivated", { bubbles: true }));
  },
};
