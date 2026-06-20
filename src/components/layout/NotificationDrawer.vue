<template>
  <el-drawer v-model="visible" title="通知中心" direction="rtl" size="360px" :append-to-body="false">
    <template #header>
      <div style="display:flex;align-items:center;justify-content:space-between;width:100%">
        <span>通知中心</span>
        <el-button size="small" text @click="notifStore.markAllRead()">全部已读</el-button>
      </div>
    </template>
    <div class="notif-tabs">
      <span :class="['ntab',{active:tab==='all'}]" @click="tab='all'">全部</span>
      <span :class="['ntab',{active:tab==='unread'}]" @click="tab='unread'">
        未读 <el-badge :value="notifStore.unreadCount" :max="99" />
      </span>
    </div>
    <div class="notif-list">
      <div
        v-for="n in filteredList" :key="n.id"
        class="notif-item" :class="{ unread: !n.is_read }"
        @click="handleClick(n)"
      >
        <div class="ni-icon">{{ typeIcon(n.type) }}</div>
        <div class="ni-body">
          <div class="ni-title">{{ n.title }}</div>
          <div class="ni-content">{{ n.content }}</div>
          <div class="ni-time">{{ formatTime(n.created_at) }}</div>
        </div>
        <div v-if="!n.is_read" class="ni-dot"></div>
      </div>
      <el-empty v-if="!filteredList.length" description="暂无通知" :image-size="80" />
    </div>
  </el-drawer>
</template>

<script setup>
import { ref, computed, inject } from 'vue'
import { useRouter } from 'vue-router'
import { useNotificationStore } from '@/stores/notification'
import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/zh-cn'
dayjs.extend(relativeTime)
dayjs.locale('zh-cn')

const props = defineProps({ modelValue: Boolean })
const emit = defineEmits(['update:modelValue'])
const visible = computed({ get: () => props.modelValue, set: v => emit('update:modelValue', v) })

const notifStore = useNotificationStore()
const router = useRouter()
const tab = ref('all')

const filteredList = computed(() =>
  tab.value === 'unread' ? notifStore.list.filter(n => !n.is_read) : notifStore.list
)

const iconMap = { approval: '✅', warning: '⚠️', payment: '💰', system: '🔧', announcement: '📢' }
function typeIcon(type) { return iconMap[type] || '🔔' }
function formatTime(t) { return dayjs(t).fromNow() }

async function handleClick(n) {
  await notifStore.markRead(n.id)
  if (n.action_url) router.push(n.action_url)
}
</script>

<style scoped lang="scss">
.notif-tabs { display:flex; gap:16px; padding:0 0 12px; border-bottom:1px solid var(--el-border-color); margin-bottom:12px; }
.ntab { font-size:13px; color:var(--el-text-color-secondary); cursor:pointer; padding:4px 0;
  &.active { color:var(--el-color-primary); border-bottom:2px solid var(--el-color-primary); } }
.notif-list { display:flex; flex-direction:column; gap:0; }
.notif-item {
  display:flex; gap:10px; padding:12px 0; border-bottom:1px solid var(--el-border-color);
  cursor:pointer; transition:background .15s; position:relative;
  &:hover { background:var(--el-fill-color); }
  &.unread { background:rgba(var(--el-color-primary-rgb),.04); }
}
.ni-icon { font-size:22px; flex-shrink:0; }
.ni-body { flex:1; }
.ni-title { font-size:13px; font-weight:500; color:var(--el-text-color-primary); margin-bottom:4px; }
.ni-content { font-size:12px; color:var(--el-text-color-secondary); line-height:1.5; margin-bottom:4px; }
.ni-time { font-size:11px; color:var(--el-text-color-placeholder); }
.ni-dot { width:7px; height:7px; background:var(--el-color-primary); border-radius:50%; flex-shrink:0; margin-top:4px; }
</style>
