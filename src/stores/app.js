import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', {
  state: () => ({
    sidebarCollapsed: false,
    darkMode: true,
    tabs: [{ id: 'dashboard', title: '仪表盘', icon: 'Odometer', path: '/' }],
    activeTab: 'dashboard',
    loading: false,
    breadcrumb: [],
    systemConfig: {}
  }),
  actions: {
    toggleSidebar() { this.sidebarCollapsed = !this.sidebarCollapsed },
    addTab(tab) {
      if (!this.tabs.find(t => t.id === tab.id)) this.tabs.push(tab)
      this.activeTab = tab.id
    },
    removeTab(id) {
      const idx = this.tabs.findIndex(t => t.id === id)
      if (idx === -1 || this.tabs.length === 1) return
      this.tabs.splice(idx, 1)
      if (this.activeTab === id) this.activeTab = this.tabs[Math.max(0, idx - 1)].id
    }
  }
})
