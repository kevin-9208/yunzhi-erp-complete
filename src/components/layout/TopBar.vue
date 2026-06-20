<template>
  <header class="topbar">
    <div class="topbar-left">
      <el-button :icon="appStore.sidebarCollapsed ? 'Expand' : 'Fold'" text @click="appStore.toggleSidebar" />
      <el-breadcrumb separator="/">
        <el-breadcrumb-item v-for="b in appStore.breadcrumb" :key="b.path" :to="b.path">{{ b.title }}</el-breadcrumb-item>
      </el-breadcrumb>
    </div>
    <div class="topbar-right">
      <el-input v-model="searchQuery" placeholder="全局搜索 Ctrl+K" prefix-icon="Search" style="width:220px" size="default" clearable />
      <el-tooltip content="新建">
        <el-button :icon="'Plus'" circle @click="showQuickCreate = true" />
      </el-tooltip>
      <el-tooltip content="消息通知">
        <el-badge :value="notifStore.unreadCount" :max="99" :hidden="!notifStore.unreadCount">
          <el-button :icon="'Bell'" circle @click="emit('toggleNotif')" />
        </el-badge>
      </el-tooltip>
      <el-tooltip content="全屏">
        <el-button :icon="isFullscreen ? 'Minus' : 'FullScreen'" circle @click="toggleFullscreen" />
      </el-tooltip>
      <el-dropdown trigger="click" @command="handleUserCmd">
        <div class="user-avatar">
          <el-avatar :size="32" :src="authStore.avatar">{{ authStore.userName?.[0] }}</el-avatar>
          <span class="user-name">{{ authStore.userName }}</span>
          <el-icon><ArrowDown /></el-icon>
        </div>
        <template #dropdown>
          <el-dropdown-menu>
            <el-dropdown-item command="profile" icon="User">个人信息</el-dropdown-item>
            <el-dropdown-item command="settings" icon="Setting">系统设置</el-dropdown-item>
            <el-dropdown-item command="logout" icon="SwitchButton" divided>退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </template>
      </el-dropdown>
    </div>
    <!-- Quick Create Dialog -->
    <el-dialog v-model="showQuickCreate" title="快速创建" width="480px" align-center>
      <div class="quick-create-grid">
        <div v-for="item in quickItems" :key="item.path" class="quick-item" @click="quickNav(item.path)">
          <span class="qi-icon">{{ item.icon }}</span>
          <span>{{ item.title }}</span>
        </div>
      </div>
    </el-dialog>
  </header>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useAuthStore } from '@/stores/auth'
import { useNotificationStore } from '@/stores/notification'
import { ElMessageBox, ElMessage } from 'element-plus'

const emit = defineEmits(['toggleNotif'])
const router = useRouter()
const appStore = useAppStore()
const authStore = useAuthStore()
const notifStore = useNotificationStore()
const searchQuery = ref('')
const showQuickCreate = ref(false)
const isFullscreen = ref(false)

const quickItems = [
  { icon: '📦', title: '新建销售订单', path: '/crm/sales-orders' },
  { icon: '🛒', title: '新建采购订单', path: '/purchase/orders' },
  { icon: '👤', title: '新增员工', path: '/hrm/employees' },
  { icon: '🧾', title: '费用报销', path: '/finance/expenses' },
  { icon: '🎯', title: '新建商机', path: '/crm/leads' },
  { icon: '📢', title: '发布公告', path: '/oa/announcements' },
]

function toggleFullscreen() {
  if (!document.fullscreenElement) { document.documentElement.requestFullscreen(); isFullscreen.value = true }
  else { document.exitFullscreen(); isFullscreen.value = false }
}

function quickNav(path) { showQuickCreate.value = false; router.push(path) }

async function handleUserCmd(cmd) {
  if (cmd === 'logout') {
    await ElMessageBox.confirm('确认退出登录？', '提示', { type: 'warning' })
    await authStore.signOut()
    router.push('/login')
    ElMessage.success('已安全退出')
  } else if (cmd === 'settings') {
    router.push('/system/settings')
  }
}
</script>

<style scoped lang="scss">
.topbar {
  height: 56px; background: var(--el-bg-color); border-bottom: 1px solid var(--el-border-color);
  display: flex; align-items: center; padding: 0 16px; gap: 12px; flex-shrink: 0;
  &-left { display: flex; align-items: center; gap: 8px; flex: 1; }
  &-right { display: flex; align-items: center; gap: 8px; }
}
.user-avatar {
  display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 4px 8px;
  border-radius: 6px; transition: background .15s;
  &:hover { background: var(--el-fill-color); }
  .user-name { font-size: 13px; max-width: 80px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
}
.quick-create-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 12px;
}
.quick-item {
  display: flex; align-items: center; gap: 10px; padding: 14px 16px;
  border: 1px solid var(--el-border-color); border-radius: 8px; cursor: pointer;
  transition: all .15s; font-size: 14px;
  .qi-icon { font-size: 22px; }
  &:hover { border-color: var(--el-color-primary); background: var(--el-color-primary-light-9); }
}
</style>
