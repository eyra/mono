let tabbarId = "";

export const TabBar = {
  mounted() {
    console.log("[TabBar] mounted");
    tabbarId = this.el.id;

    var savedTabId = this.loadActiveTab();

    if (this.exists(savedTabId)) {
      this.show(savedTabId, true);
    } else {
      var firstTabId = this.getFirstTab();
      var initialTabId = this.el.dataset.initialTab ?? undefined;

      console.log("[TabBar] initialTabId", initialTabId);

      this.show(initialTabId ?? firstTabId, true);
    }

    window.addEventListener("tab-content-updated", (event) => {
      console.log("[TabBar] tab-content-updated");
      this.updated();
    });
  },

  updated() {
    console.log("[TabBar] updated");
    var savedTabId = this.loadActiveTab();
    this.show(savedTabId, false);
  },

  getActiveTabKey() {
    return "tabbar://" + tabbarId + "/active_tab";
  },

  loadActiveTab() {
    const tabKey = this.getActiveTabKey();
    const activeTab = window.localStorage.getItem(tabKey);
    if (typeof activeTab === "string") {
      return activeTab;
    }
    return undefined;
  },

  saveActiveTab(tabId) {
    console.info("[TabBar] saveActiveTab ", tabId);
    window.localStorage.setItem(this.getActiveTabKey(), tabId);
  },

  getFirstTab() {
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

  show(nextTabId, scrollToTop) {
    console.log("[TabBar] nextTabId", nextTabId);
    if (nextTabId == undefined) {
      return;
    }

    this.saveActiveTab(nextTabId);

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
      window.scrollTo(0, 0);
    }
  },
};

export const Tab = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      TabBar.show(this.el.dataset.tabId, true);
    });
  },
  updated() {
    console.log("[Tab] updated");
  },
};

export const TabFooterItem = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      TabBar.show(this.el.dataset.targetTabId, true);
    });
  },
};

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
