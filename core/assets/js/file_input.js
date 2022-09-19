import { GetText } from "./gettext";

export class FileInput {
  constructor(data, locale) {
    this.data = data;
    this.locale = locale;
  }

  render(parent) {
    const { title, description } = data;

    const text = {
      title: GetText.resolve(title, locale),
      description: GetText.resolve(description, locale),
      selectButton: GetText.resolve(this.selectButtonLabel(), locale),
      continueButton: GetText.resolve(this.continueButtonLabel(), locale),
      resetButton: GetText.resolve(this.resetButtonLabel(), locale),
    };

    parent.el.innerHTML = `
      <div class="text-title5 font-title5 sm:text-title4 sm:font-title4 lg:text-title3 lg:font-title3 text-grey1">
        ${text.title}
      </div>
      <div class="mt-8"></div>

      <div id="select-panel">
        <div class="flex-wrap text-bodylarge font-body text-grey1 text-left">
          ${text.description}
        </div>
        <div class="mt-8"></div>
        <div class="flex flex-row">
          <div class="flex-wrap cursor-pointer">
            <div id="select-button" class="pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 bg-primary text-white">
              ${text.selectButton}
            </div>
          </div>
        </div>
        <input id="input" type="file" class="hidden" accept="${data.extensions}">
        <div class="mt-8"></div>
      </div>

      <div id="confirm-panel" class="hidden">
        <div class="flex flex-row">
          <div class="flex-wrap bg-grey5 rounded">
            <div class="flex flex-row h-14 px-5 items-center">
              <div id="selected-filename" class="flex-wrap text-subhead font-subhead text-grey1">filename</div>
            </div>
          </div>
        </div>
        <div class="mt-8"></div>
        <div class="text-bodylarge font-body text-grey1 text-left">
          Continue with the selected file, or select again?
        </div>
        <div class="mt-4"></div>
        <div class="flex flex-row gap-4">
          <div id="confirm-button" class="flex-wrap cursor-pointer">
            <div class="pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 bg-primary text-white">
              ${text.continueButton}
            </div>
          </div>
          <div id="reset-button" class="flex-wrap cursor-pointer">
            <div class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button rounded bg-opacity-0 pr-4 pl-4 bg-delete text-delete">
              ${text.resetButton}
            </div>
          </div>
        </div>
      </div>`;
  }

  activate(parent, resolve) {
    const input = parent.child("input");
    const selectedFilename = parent.child("selected-filename");
    const selectPanel = parent.child("select-panel");
    const selectButton = parent.child("select-button");
    const confirmPanel = parent.child("confirm-panel");
    const confirmButton = parent.child("confirm-button");
    const resetButton = parent.child("reset-button");

    selectButton.onClick(() => {
      // fake click on hidden input to trigger native file selector
      input.click();
    });

    input.onChange(() => {
      selectPanel.hide();
      confirmPanel.show();

      selectedFilename.el.innerText = input.selectedFile().name;
      selectedFilename.show();
    });

    confirmButton.onClick(() => {
      resolve(input.selectedFile());
    });

    resetButton.onClick(() => {
      // fake click on hidden input to trigger native file selector
      input.click();
    });
  }

  /* PRIVATE */

  continueButtonLabel() {
    return {
      en: "Continue",
      nl: "Doorgaan",
    };
  }

  selectButtonLabel() {
    return {
      en: "Select file",
      nl: "Selecteer bestand",
    };
  }

  resetButtonLabel() {
    return {
      en: "Select again",
      nl: "Opnieuw",
    };
  }
}
