let activeTabId = ""

export const Tabbar = {
    mounted() {
        var initialTab = "tab_"+this.el.getAttribute("data-initial-tab")
        this.show(initialTab, true)

    },
    updated() {
        this.show(activeTabId, false)
    },

    show(nextTabId, scrollToTop) {
        activeTabId = nextTabId
        var tabs = Array.from(document.querySelectorAll('[id^="tab_"]'));

        // Skip unknown tab
        if (!tabs.some(tab => tab.id === nextTabId )) {
            console.warn("Skip unknown tab", nextTabId)
            return
        }

        // Show active tab
        tabs.forEach(tab => {
            var isVisible = tab.id === nextTabId
            setVisible(tab, isVisible)
        });

        // Activate tabbar item for active tab
        var tabbar_items = Array.from(document.getElementsByClassName('tabbar-item'));
        tabbar_items.forEach(tabbar_item => {
            var tab_id = "tab_"+tabbar_item.getAttribute("data-tab-id")
            updateTabbarItem(tabbar_item, tab_id === nextTabId)
        });

        // Show footer item for active tab
        var tabbar_footer_items = Array.from(document.getElementsByClassName('tabbar-footer-item'));
        tabbar_footer_items.forEach(tabbar_footer_item => {
            var tab_id = "tab_"+tabbar_footer_item.getAttribute("data-tab-id")
            var isVisible = tab_id === nextTabId
            setVisible(tabbar_footer_item, isVisible)
        });

        if (scrollToTop) {
            window.scrollTo(0, 0);
        }
    }
}

export const TabbarItem = {
    mounted() {
        this.el.addEventListener("click", (event)=>{
            this.tabbar = document.getElementById("tabbar");
            Tabbar.show("tab_"+this.el.getAttribute("data-tab-id"), true)
        })
    }
  }

  export const TabbarFooterItem = {
    mounted() {
        this.el.addEventListener("click", (event)=>{
            this.tabbar = document.getElementById("tabbar");
            Tabbar.show("tab_"+this.el.getAttribute("data-target-tab-id"), true)
        })
    }
  }

function setVisible(element, isVisible) {
    element.classList[ isVisible ? 'remove' : 'add' ]('hidden')
};

function updateTabbarItem (tabbar_item, activate) {
    var hideWhenIdle =
        Array.from(tabbar_item.classList).filter((clazz) => {
            return clazz === "hide-when-idle"
        }).length > 0

    if (hideWhenIdle) {
        setVisible(tabbar_item, activate)
    }

    var icon = tabbar_item.getElementsByClassName('icon')[0]
    var title = tabbar_item.getElementsByClassName('title')[0]
    updateElement(icon, activate)
    updateElement(title, activate)
}

function updateElement(element, activate) {
    var idle_classes = customClasses(element, 'idle');
    var active_classes = customClasses(element, 'active');

    if (activate) {
        updateClassList(element, idle_classes, 'remove')
        updateClassList(element, active_classes, 'add')
    } else {
        updateClassList(element, active_classes, 'remove')
        updateClassList(element, idle_classes, 'add')
    }
}

function customClasses(element, name) {
    return element.getAttribute(name+'-class').split(' ');
}

function updateClassList(element, classes, type) {
    classes.forEach(clazz => {
        element.classList[type](clazz)
    })
}
