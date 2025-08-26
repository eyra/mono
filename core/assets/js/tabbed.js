import { MainContent } from "./main_content";

/**
 * TabBar component
 *
 * The TabBar component is responsible for managing the state of tabs and tab panels. It saves the
 * active tab in local storage to restore the active tab when the page is reloaded.
 *
 * TabBar contains multiple tabs and and TabContent contains multiple tab panels.
 * TabContent notifies TabBar when its content has been updated.
 *
 * Tabs are clickable elements that can be used to switch between different views.
 * Tab panels are hidden by default and are shown when the corresponding tab is clicked.
 *
 */
export const TabBar = {
  mounted() {
    console.log("[TabBar] mounted");
    this.barId = this.el.id;
    console.log("[TabBar] barId", this.barId);

    this.show(this.getActiveTabId(), true);

    // Tab notifies TabBar when it has been clicked.
    window.addEventListener("tab-clicked", (event) => {
      if (event.target.dataset.barId == this.barId) {
        console.log("[TabBar] tab-clicked", event.target.dataset.barId);
        console.log("[TabBar] tab-clicked", event.target.dataset.tabId);
        this.show(event.target.dataset.tabId, false);
      }
    });

    // TabFooterItem notifies TabBar when it has been clicked.
    window.addEventListener("tab-footer-item-clicked", (event) => {
      console.log("[TabBar] tab-footer-item-clicked", event);
      this.show(event.target.dataset.targetTabId, true);
    });

    // TabContent notifies TabBar when its content has been updated.
    window.addEventListener("tab-content-updated", (event) => {
      console.log("[TabBar] tab-content-updated");
      this.updated();
    });
  },

  updated() {
    console.log("[TabBar] updated");
    var savedTabId = this.loadActiveTabId();
    this.show(savedTabId, false);
  },

  onBeforeElUpdated(from, to) {
    // Each tab has a corresponding tab panel. Tab panels are hidden by default.
    // The hidden state of tab panels is controlled client side by the TabBar component.
    // Restore active tab panel by syncing the hidden state.

    if (from.classList.contains("tab-panel")) {
      if (!from.classList.contains("hidden")) {
        console.log("[TabBar] restore active tab", from, to);
        to.classList.remove("hidden");
      }
    }
  },

  getActiveTabId() {
    var initialTabId = this.el.dataset.initialTab;
    if (this.exists(initialTabId)) {
      return initialTabId;
    }

    var savedTabId = this.loadActiveTabId();
    if (this.exists(savedTabId)) {
      return savedTabId;
    }

    var firstTabId = this.getFirstTabId();
    if (this.exists(firstTabId)) {
      return firstTabId;
    }

    console.error("[TabBar] No active tab");
    return undefined;
  },

  getActiveTabKey() {
    active_tab_key = "tabbar://" + this.barId + "/active_tab";
    console.info("[TabBar] getActiveTabKey ", active_tab_key);
    return active_tab_key;
  },

  loadActiveTabId() {
    const tabKey = this.getActiveTabKey();
    const activeTab = window.localStorage.getItem(tabKey);
    if (typeof activeTab === "string") {
      return activeTab;
    }
    return undefined;
  },

  saveActiveTabId(tabId) {
    console.info("[TabBar] saveActiveTabId ", tabId);
    window.localStorage.setItem(this.getActiveTabKey(), tabId);
  },

  getFirstTabId() {
    var tabs = Array.from(document.getElementsByClassName("tab"));
    if (tabs == undefined) {
      return undefined;
    } else {
      return tabs[0].dataset.tabId;
    }
  },

  exists(tabId) {
    var tabs = Array.from(document.getElementsByClassName("tab"));
    return tabs.some((tab) => tab.dataset.tabId === tabId);
  },

  /**
   * Show tab with given tab id.
   * It is safe to call this method with an unknown tab id (from another tab bar).
   */
  show(nextTabId, scrollToTop) {
    console.log("[TabBar] nextTabId", nextTabId);
    if (nextTabId == undefined) {
      return;
    }

    var tabs = Array.from(document.getElementsByClassName("tab"));
    var tab_panels = Array.from(document.getElementsByClassName("tab-panel"));
    var tab_footer_items = Array.from(
      document.getElementsByClassName("tab-footer-item")
    );

    // Skip unknown tab
    if (!tabs.some((tab) => tab.dataset.tabId === nextTabId)) {
      console.warn("[TabBar] Skip unknown tab", nextTabId);
      return;
    }

    this.saveActiveTabId(nextTabId);

    // Activate active tab
    tabs.forEach((tab) => {
      updateTab(tab, tab.dataset.tabId === nextTabId);
    });

    // Show panel for active tab
    tab_panels.forEach((tab_panel) => {
      var isVisible = tab_panel.dataset.tabId === nextTabId;
      setVisible(tab_panel, isVisible);
    });

    // Show footer item for active tab
    tab_footer_items.forEach((tab_footer_item) => {
      var isVisible = tab_footer_item.dataset.tabId === nextTabId;
      setVisible(tab_footer_item, isVisible);
    });

    if (scrollToTop) {
      console.log("[TabBar] scrollToTop");
      MainContent.scrollToTop(this.el);
    }
  },
};

/**
 * Tab component
 *
 * Tabs are clickable elements that can be used to switch between different views.
 */
export const Tab = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      this.el.dispatchEvent(new Event("tab-clicked", { bubbles: true }));
    });
  },
};

/**
 * TabFooterItem component
 *
 * TabFooterItem is a clickable element that can be used to switch to next tab.
 * It has a corresponding tab panel that is shown when the TabFooterItem is clicked.
 * The tab id is stored in the data-target-tab-id attribute.
 */
export const TabFooterItem = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      this.el.dispatchEvent(
        new Event("tab-footer-item-clicked", { bubbles: true })
      );
    });
  },
};

/**
 * TabContent component
 *
 * TabContent notifies TabBar when its content has been updated.
 */
export const TabContent = {
  mounted() {
    console.log("[TabContent] mounted");
  },
  updated() {
    console.log("[TabContent] updated");
    this.el.dispatchEvent(new Event("tab-content-updated", { bubbles: true }));
  },
};

function setVisible(element, isVisible) {
  element.classList[isVisible ? "remove" : "add"]("hidden");
}

function updateTab(tab, activate) {
  var hideWhenIdle =
    Array.from(tab.classList).filter((clazz) => {
      return clazz === "hide-when-idle";
    }).length > 0;

  if (hideWhenIdle) {
    console.log("hideWhenIdle", hideWhenIdle);
    setVisible(tab, activate);
  }

  var icon = tab.getElementsByClassName("icon")[0];
  var title = tab.getElementsByClassName("title")[0];

  updateElement(tab, activate);
  if (icon) {
    updateElement(icon, activate);
  }
  updateElement(title, activate);

  if (activate) {
    tab.dispatchEvent(new Event("tab-activated", { bubbles: true }));
  }
}

function updateElement(element, activate) {
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
