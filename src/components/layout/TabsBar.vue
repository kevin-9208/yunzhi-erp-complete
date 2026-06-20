<template>
  <div class="tabs-bar" v-if="appStore.tabs.length">
    <div class="tabs-scroll">
      <div
        v-for="tab in appStore.tabs"
        :key="tab.id"
        class="tab-item"
        :class="{ active: tab.id === appStore.activeTab }"
        @click="switchTab(tab)"
        @contextmenu.prevent="showCtxMenu($event, tab)"
      >
        <span class="tab-title">{{ tab.title }}</span>
        <el-icon v-if="appStore.tabs.length > 1" class="tab-close" @click.stop="appStore.removeTab(tab.id)">
          <Close />
        </el-icon>
      </div>
    </div>
    <el-dropdown trigger="click" class="tabs-action">
      <el-button text size="small" :icon="'ArrowDown'" />
      <template #dropdown>
        <el-dropdown-menu>
          <el-dropdown-item @click="closeOthers">关闭其他标签</el-dropdown-item>
          <el-dropdown-item @click="closeAll">关闭所有标签</el-dropdown-item>
          <el-dropdown-item @click="refresh">刷新当前页</el-dropdown-item>
        </el-dropdown-menu>
      </template>
    </el-dropdown>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'

const router = useRouter()
const appStore = useAppStore()

function switchTab(tab) {
  appStore.activeTab = tab.id
  router.push(tab.path)
}
function closeOthers() {
  const cur = appStore.tabs.find(t => t.id === appStore.activeTab)
  appStore.tabs = cur ? [cur] : appStore.tabs.slice(0, 1)
}
function closeAll() {
  const first = appStore.tabs[0]
  appStore.tabs = [first]
  appStore.activeTab = first.id
  router.push(first.path)
}
function refresh() { router.go(0) }
function showCtxMenu(e, tab) { /* context menu placeholder */ }
</script>

<style scoped lang="scss">
.tabs-bar {
  display: flex; align-items: center; background: var(--el-bg-color);
  border-bottom: 1px solid var(--el-border-color); flex-shrink: 0;
}
.tabs-scroll {
  display: flex; overflow-x: auto; flex: 1;
  &::-webkit-scrollbar { height: 3px; }
  &::-webkit-scrollbar-thumb { background: var(--el-border-color); border-radius: 2px; }
}
.tab-item {
  display: flex; align-items: center; gap: 6px; padding: 8px 14px;
  border-right: 1px solid var(--el-border-color); cursor: pointer;
  color: var(--el-text-color-secondary); font-size: 12px; white-space: nowrap;
  transition: all .15s; flex-shrink: 0;
  &:hover { background: var(--el-fill-color); color: var(--el-text-color-primary); }
  &.active {
    background: var(--el-bg-color-page); color: var(--el-color-primary);
    border-bottom: 2px solid var(--el-color-primary); margin-bottom: -1px;
  }
  .tab-close {
    font-size: 12px; color: var(--el-text-color-placeholder); border-radius: 3px; padding: 1px;
    &:hover { background: var(--el-color-danger-light-8); color: var(--el-color-danger); }
  }
}
.tabs-action { padding: 0 8px; }
</style>
