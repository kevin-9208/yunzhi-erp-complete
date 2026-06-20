import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import NProgress from 'nprogress'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { public: true, title: '登录' }
  },
  {
    path: '/',
    component: () => import('@/components/layout/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/dashboard' },
      { path: 'dashboard', name: 'Dashboard', component: () => import('@/views/dashboard/Index.vue'), meta: { title: '仪表盘', icon: 'Odometer', tabId: 'dashboard' } },
      { path: 'bi', name: 'BI', component: () => import('@/views/bi/Index.vue'), meta: { title: '数据分析', icon: 'TrendCharts', tabId: 'bi' } },

      // HRM
      { path: 'hrm/employees', name: 'Employees', component: () => import('@/views/hrm/Employees.vue'), meta: { title: '员工档案', tabId: 'employees' } },
      { path: 'hrm/org', name: 'Org', component: () => import('@/views/hrm/Org.vue'), meta: { title: '组织架构', tabId: 'org' } },
      { path: 'hrm/attendance', name: 'Attendance', component: () => import('@/views/hrm/Attendance.vue'), meta: { title: '考勤管理', tabId: 'attendance' } },
      { path: 'hrm/payroll', name: 'Payroll', component: () => import('@/views/hrm/Payroll.vue'), meta: { title: '薪资管理', tabId: 'payroll' } },
      { path: 'hrm/recruit', name: 'Recruit', component: () => import('@/views/hrm/Recruit.vue'), meta: { title: '招聘管理', tabId: 'recruit' } },

      // CRM
      { path: 'crm/customers', name: 'Customers', component: () => import('@/views/crm/Customers.vue'), meta: { title: '客户管理', tabId: 'customers' } },
      { path: 'crm/leads', name: 'Leads', component: () => import('@/views/crm/Leads.vue'), meta: { title: '商机看板', tabId: 'leads' } },
      { path: 'crm/sales-orders', name: 'SalesOrders', component: () => import('@/views/crm/SalesOrders.vue'), meta: { title: '销售订单', tabId: 'sales_orders' } },
      { path: 'crm/quotations', name: 'Quotations', component: () => import('@/views/crm/Quotations.vue'), meta: { title: '报价管理', tabId: 'quotations' } },

      // Purchase
      { path: 'purchase/suppliers', name: 'Suppliers', component: () => import('@/views/purchase/Suppliers.vue'), meta: { title: '供应商管理', tabId: 'suppliers' } },
      { path: 'purchase/requisitions', name: 'Requisitions', component: () => import('@/views/purchase/Requisitions.vue'), meta: { title: '采购申请', tabId: 'purchase_req' } },
      { path: 'purchase/orders', name: 'PurchaseOrders', component: () => import('@/views/purchase/Orders.vue'), meta: { title: '采购订单', tabId: 'purchase_orders' } },

      // WMS
      { path: 'wms/warehouses', name: 'Warehouses', component: () => import('@/views/wms/Warehouses.vue'), meta: { title: '仓库管理', tabId: 'warehouses' } },
      { path: 'wms/inventory', name: 'Inventory', component: () => import('@/views/wms/Inventory.vue'), meta: { title: '库存总览', tabId: 'inventory' } },
      { path: 'wms/inbound', name: 'Inbound', component: () => import('@/views/wms/Inbound.vue'), meta: { title: '入库单', tabId: 'inventory_in' } },
      { path: 'wms/outbound', name: 'Outbound', component: () => import('@/views/wms/Outbound.vue'), meta: { title: '出库单', tabId: 'inventory_out' } },
      { path: 'wms/stocktake', name: 'Stocktake', component: () => import('@/views/wms/Stocktake.vue'), meta: { title: '库存盘点', tabId: 'stocktake' } },

      // Finance
      { path: 'finance/receivables', name: 'Receivables', component: () => import('@/views/finance/Receivables.vue'), meta: { title: '应收账款', tabId: 'receivables' } },
      { path: 'finance/payables', name: 'Payables', component: () => import('@/views/finance/Payables.vue'), meta: { title: '应付账款', tabId: 'payables' } },
      { path: 'finance/expenses', name: 'Expenses', component: () => import('@/views/finance/Expenses.vue'), meta: { title: '费用报销', tabId: 'expenses' } },
      { path: 'finance/ledger', name: 'Ledger', component: () => import('@/views/finance/Ledger.vue'), meta: { title: '总账凭证', tabId: 'ledger' } },
      { path: 'finance/reports', name: 'FinanceReports', component: () => import('@/views/finance/Reports.vue'), meta: { title: '财务报表', tabId: 'finance_report' } },

      // OA
      { path: 'oa/announcements', name: 'Announcements', component: () => import('@/views/oa/Announcements.vue'), meta: { title: '公告通知', tabId: 'announcements' } },
      { path: 'oa/meetings', name: 'Meetings', component: () => import('@/views/oa/Meetings.vue'), meta: { title: '会议预约', tabId: 'meetings' } },
      { path: 'oa/files', name: 'Files', component: () => import('@/views/oa/Files.vue'), meta: { title: '文件管理', tabId: 'files' } },
      { path: 'oa/todos', name: 'Todos', component: () => import('@/views/oa/Todos.vue'), meta: { title: '待办事项', tabId: 'todos' } },
      { path: 'oa/knowledge', name: 'Knowledge', component: () => import('@/views/oa/Knowledge.vue'), meta: { title: '企业知识库', tabId: 'knowledge' } },

      // Workflow
      { path: 'workflow/approval', name: 'Approval', component: () => import('@/views/system/Approval.vue'), meta: { title: '审批中心', tabId: 'approval' } },
      { path: 'workflow/designer', name: 'WorkflowDesigner', component: () => import('@/views/system/WorkflowDesigner.vue'), meta: { title: '工作流设计器', tabId: 'workflow' } },

      // System
      { path: 'system/roles', name: 'Roles', component: () => import('@/views/system/Roles.vue'), meta: { title: '角色权限', tabId: 'roles' } },
      { path: 'system/dict', name: 'Dict', component: () => import('@/views/system/Dict.vue'), meta: { title: '数据字典', tabId: 'dict' } },
      { path: 'system/settings', name: 'Settings', component: () => import('@/views/system/Settings.vue'), meta: { title: '系统设置', tabId: 'settings' } },
      { path: 'system/logs', name: 'Logs', component: () => import('@/views/system/Logs.vue'), meta: { title: '日志中心', tabId: 'logs' } },

      // Messages
      { path: 'messages', name: 'Messages', component: () => import('@/views/Messages.vue'), meta: { title: '消息中心', tabId: 'messages' } },
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/' }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 })
})

router.beforeEach(async (to) => {
  NProgress.start()
  const auth = useAuthStore()
  if (!auth.initialized) await auth.initAuth()
  if (to.meta.requiresAuth && !auth.isAuthenticated) return '/login'
  if (to.path === '/login' && auth.isAuthenticated) return '/'
  document.title = `${to.meta.title || '云智ERP'} | 云智企业管理平台`
})

router.afterEach(() => NProgress.done())

export default router
