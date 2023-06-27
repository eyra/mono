let liveContentId = "";
let liveContentShowErrors = false;
let liveContentActiveField = "";

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
    liveContentId = this.el.id;
    liveContentShowErrors = this.el.getAttribute(DATA_SHOW_ERRORS) != null;

    this.el.addEventListener("click", (event) => {
      makeActive(undefined);
    });

    applyErrors();
    makeActive(undefined);
  },

  updated() {
    liveContentShowErrors = this.el.getAttribute(DATA_SHOW_ERRORS) != null;
    applyErrors();
  },

  onBeforeElUpdated(from, to) {
    const field_id = from.getAttribute("__eyra_field_id");

    if (field_id != null) {
      updateFieldItem(to, field_id);
    }
  },
};

export const LiveField = {
  mounted() {
    const fieldId = this.el.dataset.fieldId;
    const input = this.el.getElementsByClassName(FIELD_INPUT_TYPE)[0];

    if (input) {
      input.addEventListener("click", (event) => {
        event.stopPropagation();
        makeActive(fieldId);
      });

      input.addEventListener("focus", (event) => {
        event.stopPropagation();
        makeActive(fieldId);
      });

      input.addEventListener("blur", (event) => {
        event.stopPropagation();
        makeActive(undefined);
      });
    }
  },
};

function applyErrors() {
  const fieldErrors = Array.from(
    document.querySelectorAll(`.${FIELD_ERROR_TYPE}`)
  );
  if (liveContentShowErrors) {
    fieldErrors.forEach((fieldError) => fieldError.classList.remove(HIDDEN));
  } else {
    fieldErrors.forEach((fieldError) => fieldError.classList.add(HIDDEN));
  }
}

function makeActive(fieldId) {
  liveContentActiveField = fieldId;
  var fields = Array.from(document.querySelectorAll('[id^="field-"]'));
  fields.forEach((field) => {
    var activate = field.dataset.fieldId === fieldId;
    updateField(field, activate);
  });
}

function updateField(field, activate) {
  const label = field.getElementsByClassName(FIELD_LABEL_TYPE)[0];
  const input = field.getElementsByClassName(FIELD_INPUT_TYPE)[0];

  const hasErrors = field.getElementsByClassName(FIELD_ERROR_TYPE)[0] != null;

  if (label) {
    updateFieldLabel(label, activate, hasErrors);
  }

  if (input) {
    updateFieldInput(input, activate, hasErrors);
  }
}

function updateFieldItem(fieldItem, field) {
  const activate = field == liveContentActiveField;
  const hasErrors = fieldItem.getAttribute(HAS_ERRORS_ATTR) != null;

  if (fieldItem.classList.contains(FIELD_LABEL_TYPE)) {
    updateFieldLabel(fieldItem, activate, hasErrors);
  } else if (fieldItem.classList.contains(FIELD_INPUT_TYPE)) {
    updateFieldInput(fieldItem, activate, hasErrors);
  }
}

function updateFieldLabel(label, activate, hasErrors) {
  updateFieldItemClass(label, activate, hasErrors, LABEL_IDLE, LABEL_ERROR);
}

function updateFieldInput(input, activate, hasErrors) {
  updateFieldItemClass(input, activate, hasErrors, INPUT_IDLE, INPUT_ERROR);
}

function updateFieldItemClass(
  fieldItem,
  activate,
  hasErrors,
  idle_class,
  error_class
) {
  var dynamic_class = idle_class;
  if (activate) {
    dynamic_class = fieldItem.getAttribute(ACTIVE_COLOR_ATTR);
  } else if (liveContentShowErrors && hasErrors) {
    dynamic_class = error_class;
  }
  const static_class = fieldItem.getAttribute(STATIC_CLASS_ATTR);
  fieldItem.setAttribute("class", static_class + " " + dynamic_class);
}
