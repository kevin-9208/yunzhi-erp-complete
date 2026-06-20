<template>
  <el-menu
    :default-active="activeMenu"
    :collapse="appStore.sidebarCollapsed"
    background-color="transparent"
    text-color="var(--el-text-color-secondary)"
    active-text-color="var(--el-color-primary)"
    router
    class="sidebar-menu"
  >
    <template v-for="group in menuGroups" :key="group.label">
      <div class="menu-label" v-if="!appStore.sidebarCollapsed">{{ group.label }}</div>
      <template v-for="item in group.items" :key="item.path">
        <el-menu-item :index="item.path">
          <el-icon><component :is="item.icon" /></el-icon>
          <template #title>
            {{ item.title }}
            <el-badge v-if="item.badge" :value="item.badge" class="menu-badge" type="danger" />
          </template>
        </el-menu-item>
      </template>
    </template>
  </el-menu>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useNotificationStore } from '@/stores/notification'

const appStore = useAppStore()
const notifStore = useNotificationStore()
const route = useRoute()
const activeMenu = computed(() => route.path)

const pendingApprovals = computed(() => 3) // from workflow store

const menuGroups = computed(() => [
  {
    label: '工作台',
    items: [
      { path: '/dashboard', title: '仪表盘', icon: 'Odometer' },
      { path: '/bi', title: '数据分析 BI', icon: 'TrendCharts' },
      { path: '/messages', title: '消息中心', icon: 'Message', badge: notifStore.unreadCount || null },
      { path: '/workflow/approval', title: '审批中心', icon: 'Checked', badge: pendingApprovals.value || null },
      { path: '/workflow/designer', title: '工作流设计', icon: 'Share' },
    ]
  },
  {
    label: '人力资源 HRM',
    items: [
      { path: '/hrm/employees', title: '员工档案', icon: 'User' },
      { path: '/hrm/org', title: '组织架构', icon: 'OfficeBuilding' },
      { path: '/hrm/attendance', title: '考勤管理', icon: 'Clock' },
      { path: '/hrm/payroll', title: '薪资管理', icon: 'Money' },
      { path: '/hrm/recruit', title: '招聘管理', icon: 'DocumentAdd' },
    ]
  },
  {
    label: '销售 CRM',
    items: [
      { path: '/crm/customers', title: '客户管理', icon: 'School' },
      { path: '/crm/leads', title: '商机看板', icon: 'Aim' },
      { path: '/crm/sales-orders', title: '销售订单', icon: 'ShoppingBag' },
      { path: '/crm/quotations', title: '报价管理', icon: 'Tickets' },
    ]
  },
  {
    label: '采购管理',
    items: [
      { path: '/purchase/suppliers', title: '供应商管理', icon: 'Factory' },
      { path: '/purchase/requisitions', title: '采购申请', icon: 'Document' },
      { path: '/purchase/orders', title: '采购订单', icon: 'ShoppingCart' },
    ]
  },
  {
    label: '库存 WMS',
    items: [
      { path: '/wms/warehouses', title: '仓库管理', icon: 'House' },
      { path: '/wms/inventory', title: '库存总览', icon: 'Box' },
      { path: '/wms/inbound', title: '入库单', icon: 'Download' },
      { path: '/wms/outbound', title: '出库单', icon: 'Upload' },
      { path: '/wms/stocktake', title: '库存盘点', icon: 'Search' },
    ]
  },
  {
    label: '财务管理',
    items: [
      { path: '/finance/receivables', title: '应收账款', icon: 'CreditCard' },
      { path: '/finance/payables', title: '应付账款', icon: 'Coin' },
      { path: '/finance/expenses', title: '费用报销', icon: 'Wallet' },
      { path: '/finance/ledger', title: '总账凭证', icon: 'Notebook' },
      { path: '/finance/reports', title: '财务报表', icon: 'DataAnalysis' },
    ]
  },
  {
    label: 'OA 办公',
    items: [
      { path: '/oa/announcements', title: '公告通知', icon: 'Bell' },
      { path: '/oa/meetings', title: '会议预约', icon: 'Calendar' },
      { path: '/oa/files', title: '文件管理', icon: 'Folder' },
      { path: '/oa/todos', title: '待办事项', icon: 'List' },
      { path: '/oa/knowledge', title: '企业知识库', icon: 'Reading' },
    ]
  },
  {
    label: '系统管理',
    items: [
      { path: '/system/roles', title: '角色权限 RBAC', icon: 'Lock' },
      { path: '/system/dict', title: '数据字典', icon: 'Collection' },
      { path: '/system/settings', title: '系统设置', icon: 'Setting' },
      { path: '/system/logs', title: '日志中心', icon: 'Memo' },
    ]
  }
])
</script>

<style scoped lang="scss">
.sidebar-menu { border-right: none; }
.menu-label {
  padding: 6px 16px 3px;
  font-size: 10px;
  font-weight: 600;
  color: var(--el-text-color-placeholder);
  letter-spacing: 1px;
  text-transform: uppercase;
}
.menu-badge { margin-left: auto; }
</style>
