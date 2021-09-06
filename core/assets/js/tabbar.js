let activeTabId = ""

export const Tabbar = {
    mounted() {
        var initialTab = "tab_"+this.el.getAttribute("initial-tab")
        this.show(initialTab)        
        
    },
    updated() {
        this.show(activeTabId)
    },

    show(nextTabId) {
        activeTabId = nextTabId
        var tabs = Array.from(document.querySelectorAll('[id^="tab_"]'));

        if (tabs.filter((tab) => { return tab.id === nextTabId }).length === 0) {
            // skip unknown tab    
            return
        }


        // Show active tab
        tabs.forEach(tab => { 
            var tab_id = tab.getAttribute("id")
            var isVisible = tab_id === nextTabId  
            setVisible(tab, isVisible)
        });

        // Activate tabbar item for active tab
        var tabbar_items = Array.from(document.getElementsByClassName('tabbar-item'));
        tabbar_items.forEach(tabbar_item => { 
            var tab_id = "tab_"+tabbar_item.getAttribute("tab-id")
            updateTabbarItem(tabbar_item, tab_id === nextTabId)
        });

        // Show footer item for active tab
        var tabbar_footer_items = Array.from(document.getElementsByClassName('tabbar-footer-item'));
        tabbar_footer_items.forEach(tabbar_footer_item => { 
            var tab_id = "tab_"+tabbar_footer_item.getAttribute("tab-id")
            var isVisible = tab_id === nextTabId
            setVisible(tabbar_footer_item, isVisible)
        });

        window.scrollTo(0, 0);
    }
}

export const TabbarItem = {
    mounted() {
        this.el.addEventListener("click", (event)=>{
            this.tabbar = document.getElementById("tabbar");
            Tabbar.show("tab_"+this.el.getAttribute("tab-id"))
        })
    }
  }

  export const TabbarFooterItem = {
    mounted() {
        this.el.addEventListener("click", (event)=>{
            this.tabbar = document.getElementById("tabbar");
            Tabbar.show("tab_"+this.el.getAttribute("target-tab-id"))
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

    updateClassList(element, idle_classes, activate ? 'remove' : 'add')
    updateClassList(element, active_classes, activate ? 'add' : 'remove')
}

function customClasses(element, name) {
    return element.getAttribute(name+'-class').split(' ');
}

function updateClassList(element, classes, type) {
    classes.forEach(clazz => {
        element.classList[type](clazz)
    })
}
