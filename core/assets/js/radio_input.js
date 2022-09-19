import { GetText } from "./gettext";

export class RadioInput {
  constructor(data, locale) {
    this.data = data;
    this.locale = locale;
  }

  render(parent) {
    const { title, description } = this.data;

    let items_html = this.renderItems(this.data.items);

    const text = {
      title: GetText.resolve(title, this.locale),
      description: GetText.resolve(description, this.locale),
      continueButton: GetText.resolve(this.continueButtonLabel(), this.locale),
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
      <div class="mt-4"></div>
      <div>
        <div id="radio-group" class="flex flex-col gap-3">
          ${items_html}
        </div>
      </div>
    </div>
    <div class="mt-8"></div>
    <div class="flex flex-row">
      <div id="confirm-button" class="flex-wrap cursor-pointer hidden">
        <div class="pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 bg-primary text-white">
          ${text.continueButton}
        </div>
      </div>
    </div>`;
  }

  activate(parent, resolve) {
    const dataItems = this.data.items;
    const radioGroup = parent.child("radio-group");
    const radioItems = radioGroup.childs("radio-item");
    const confirmButton = parent.child("confirm-button");
    let selected = undefined;

    radioItems.forEach((radioItem, index) => {
      const itemId = radioItem.el.id;
      radioItem.onClick(() => {
        this.toggleGroup(radioItems, itemId);
        confirmButton.show();
        selected = index;
      });
    });

    confirmButton.onClick(() => {
      const selectedItem = dataItems[selected];
      resolve(selectedItem);
    });
  }

  /* PRIVATE */

  renderItems(items) {
    return items.map((item, index) => this.renderItem(item, index));
  }

  renderItem(item, index) {
    const itemId = `item-${index}`;
    const itemHTML = _.escape(item);
    return `
    <div id="${itemId}" class="radio-item flex flex-row gap-3 items-center cursor-pointer">
      <div>
        <img
          id="${itemId}-on"
          class="hidden"
          src="/images/icons/radio_active.svg"
          alt="${itemHTML} is selected"
        />
        <img
          id="${itemId}-off"
          class=""
          src="/images/icons/radio.svg"
          alt="Select ${itemHTML}"
        />
      </div>
      <div class="text-grey1 text-label font-label select-none mt-1">
        ${itemHTML}
      </div>
    </div>`;
  }

  continueButtonLabel() {
    return {
      en: "Continue",
      nl: "Doorgaan",
    };
  }

  toggleGroup(items, activeItemId) {
    for (let item of items) {
      this.toggleItem(item, item.el.id === activeItemId);
    }
  }

  toggleItem(item, on) {
    const item_on = item.child(`${item.el.id}-on`);
    const item_off = item.child(`${item.el.id}-off`);

    item_on.hide();
    item_off.hide();

    if (on) {
      item_on.show();
    } else {
      item_off.show();
    }
  }
}
