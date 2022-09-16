import { GetText } from "./gettext"

export const RadioInputFactory = function(data, locale) {
  return RadioInput(data, locale)
}

const RadioInput = (function(data, locale) {

  /* PUBLIC */

  function render(parent){

    let items_html = render_items(data.items)

    const { title } = data
    const { description } = data

    const text = {
      "title": GetText.resolve(title, locale),
      "description": GetText.resolve(description, locale),
      "continueButton": GetText.resolve(continueButtonLabel(), locale)
    }

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
          ${ items_html }
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
    </div>`
  }


  function activate(parent, resolve) {
    const dataItems = data.items
    const radioGroup = parent.child("radio-group")
    const radioItems = radioGroup.childs("radio-item")
    const confirmButton = parent.child("confirm-button")
    let selected = undefined

    radioItems.forEach((radioItem, index) => {
      const itemId = radioItem.el.id
      radioItem.onClick(() => {
        toggle_group(radioItems, itemId)
        confirmButton.show()
        selected = index
      })
    })

    confirmButton.onClick(() => {
      const selectedItem = dataItems[selected]
      resolve(selectedItem)
    })
  }

  /* PRIVATE */

  function render_items(items) {
    let result = ""
    items.forEach((item, index) => {
      if (index > 0) {
        result += "\n"
      }
      result += render_item(item, index)
    })
    return result
  }

  function render_item(item, index) {
    const itemId = `item-${index}`
    return `
    <div id="${itemId}" class="radio-item flex flex-row gap-3 items-center cursor-pointer">
      <div>
        <img
          id="${itemId}-on"
          class="hidden"
          src="/images/icons/radio_active.svg"
          alt="${item} is selected"
        />
        <img
          id="${itemId}-off"
          class=""
          src="/images/icons/radio.svg"
          alt="Select ${item}"
        />
      </div>
      <div class="text-grey1 text-label font-label select-none mt-1">
        ${item}
      </div>
    </div>`
  }

  function continueButtonLabel() {
    return {
      "en": "Continue",
      "nl": "Doorgaan"
    }
  }

  function toggle_group(items, activeItemId) {
    for (let item of items) {
      toggle_item(item, item.el.id === activeItemId)
    }
  }

  function toggle_item(item, on) {
    const item_on = item.child(`${item.el.id}-on`)
    const item_off = item.child(`${item.el.id}-off`)

    item_on.hide()
    item_off.hide()

    if (on) {
      item_on.show()
    } else {
      item_off.show()
    }
  }

  /* MODULE INTERFACE */

  return {
      render,
      activate
  }
})