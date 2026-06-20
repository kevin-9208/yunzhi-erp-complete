<template>
  <div class="sidebar-logo">
    <div class="logo-icon">云</div>
    <transition name="fade">
      <div v-if="!appStore.sidebarCollapsed" class="logo-text">
        <div class="logo-name">云智ERP</div>
        <div class="logo-version">ENTERPRISE v2.8</div>
      </div>
    </transition>
  </div>
</template>
<script setup>
import { useAppStore } from '@/stores/app'
const appStore = useAppStore()
</script>
<style scoped lang="scss">
.sidebar-logo {
  height: 56px; display: flex; align-items: center; gap: 10px;
  padding: 0 16px; border-bottom: 1px solid var(--el-border-color); flex-shrink: 0;
}
.logo-icon {
  width: 32px; height: 32px; border-radius: 8px; flex-shrink: 0;
  background: linear-gradient(135deg,#4f8ef7,#a855f7);
  display: flex; align-items: center; justify-content: center;
  font-weight: 700; font-size: 14px; color: #fff;
}
.logo-name { font-weight: 700; font-size: 15px; line-height: 1; }
.logo-version { font-size: 10px; color: var(--el-text-color-placeholder); letter-spacing: .5px; margin-top: 3px; }
.fade-enter-active,.fade-leave-active { transition: opacity .2s; }
.fade-enter-from,.fade-leave-to { opacity: 0; }
</style>
