<template>
  <div class="layout" :class="{ 'sidebar-collapsed': appStore.sidebarCollapsed }">
    <!-- Sidebar -->
    <aside class="sidebar">
      <SidebarLogo />
      <SidebarMenu />
    </aside>

    <!-- Main -->
    <div class="layout-main">
      <TopBar />
      <TabsBar />
      <main class="content">
        <router-view v-slot="{ Component, route }">
          <keep-alive :max="15">
            <component :is="Component" :key="route.path" />
          </keep-alive>
        </router-view>
      </main>
    </div>

    <!-- Notification drawer -->
    <NotificationDrawer />
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useAuthStore } from '@/stores/auth'
import { useNotificationStore } from '@/stores/notification'
import SidebarLogo from './SidebarLogo.vue'
import SidebarMenu from './SidebarMenu.vue'
import TopBar from './TopBar.vue'
import TabsBar from './TabsBar.vue'
import NotificationDrawer from './NotificationDrawer.vue'

const appStore = useAppStore()
const authStore = useAuthStore()
const notifStore = useNotificationStore()
const router = useRouter()
const route = useRoute()

onMounted(async () => {
  if (authStore.userId) {
    await notifStore.fetch(authStore.userId)
    notifStore.subscribe(authStore.userId)
    if (Notification.permission === 'default') Notification.requestPermission()
  }
  // Sync tabs with current route
  if (route.meta?.tabId) {
    appStore.addTab({ id: route.meta.tabId, title: route.meta.title, path: route.path })
  }
})

onUnmounted(() => notifStore.unsubscribe())
</script>

<style scoped lang="scss">
.layout {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background: var(--el-bg-color-page);

  .sidebar {
    width: 224px;
    flex-shrink: 0;
    background: var(--sidebar-bg);
    border-right: 1px solid var(--el-border-color);
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    transition: width 0.25s;
  }

  .layout-main {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .content {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
    background: var(--el-bg-color-page);
  }

  &.sidebar-collapsed .sidebar { width: 64px; }
}
</style>
