<template>
  <div class="dashboard">
    <div class="welcome-bar">
      <div>
        <h2>欢迎回来，{{ authStore.userName }} 👋</h2>
        <p>{{ today }} · {{ greeting }}</p>
      </div>
      <el-button type="primary" icon="Plus" @click="showQuickCreate=true">快速创建</el-button>
    </div>

    <!-- KPI Row -->
    <el-row :gutter="16" class="mb-4">
      <el-col :span="6" v-for="kpi in kpiCards" :key="kpi.label">
        <el-card class="kpi-card" @click="$router.push(kpi.path)">
          <div class="kpi-top">
            <div class="kpi-icon" :style="`background:${kpi.bg}`">{{ kpi.icon }}</div>
            <el-tag :type="kpi.trend==='up'?'success':'danger'" size="small" effect="plain">
              {{ kpi.trend==='up'?'↑':'↓' }} {{ kpi.change }}
            </el-tag>
          </div>
          <div class="kpi-val">{{ kpi.value }}</div>
          <div class="kpi-lbl">{{ kpi.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Charts + Quick Actions -->
    <el-row :gutter="16" class="mb-4">
      <el-col :span="14">
        <el-card>
          <template #header><CardHeader title="月度营收趋势" subtitle="2024年 · 万元" /></template>
          <div ref="lineEl" style="height:200px"></div>
        </el-card>
      </el-col>
      <el-col :span="10">
        <el-card style="height:100%">
          <template #header><CardHeader title="待办事项" ><el-button text size="small" @click="$router.push('/workflow/approval')">审批中心 →</el-button></CardHeader></template>
          <div v-for="item in pendingItems" :key="item.id" class="todo-item">
            <div :class="`todo-dot ${item.urgent?'urgent':''}`"></div>
            <div style="flex:1">
              <div style="font-size:13px;font-weight:500">{{ item.type }} · {{ item.applicant }}</div>
              <div style="font-size:11px;color:var(--el-text-color-secondary);margin-top:2px">{{ item.date }}{{ item.amount?' · '+item.amount:'' }}</div>
            </div>
            <div style="display:flex;gap:4px">
              <el-button size="small" type="success" plain @click="approve(item)">✓</el-button>
              <el-button size="small" type="danger" plain @click="reject(item)">✗</el-button>
            </div>
          </div>
          <el-empty v-if="!pendingItems.length" description="暂无待办" :image-size="60" />
        </el-card>
      </el-col>
    </el-row>

    <!-- Data Tables Row -->
    <el-row :gutter="16" class="mb-4">
      <el-col :span="12">
        <el-card>
          <template #header><CardHeader title="最新销售订单"><el-button text size="small" @click="$router.push('/crm/sales-orders')">查看全部</el-button></CardHeader></template>
          <el-table :data="recentOrders" size="small">
            <el-table-column prop="order_no" label="订单号" width="130">
              <template #default="{row}"><span style="color:var(--el-color-primary);font-size:11px;font-family:monospace">{{ row.order_no }}</span></template>
            </el-table-column>
            <el-table-column prop="customer" label="客户" show-overflow-tooltip />
            <el-table-column label="金额" width="110" align="right">
              <template #default="{row}"><span style="font-weight:600">{{ fmt.money(row.amount) }}</span></template>
            </el-table-column>
            <el-table-column label="状态" width="80" align="center">
              <template #default="{row}">
                <el-tag :type="row.status==='completed'?'success':row.status==='shipped'?'':row.status==='pending'?'warning':'danger'" size="small">
                  {{ {completed:'完成',shipped:'发货',pending:'待审',cancelled:'取消',approved:'审批'}[row.status] }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header><CardHeader title="库存预警"><el-button text size="small" @click="$router.push('/wms/inventory')">查看全部</el-button></CardHeader></template>
          <el-table :data="alertStock" size="small">
            <el-table-column prop="name" label="产品" show-overflow-tooltip />
            <el-table-column prop="qty" label="库存" width="70" align="center">
              <template #default="{row}"><span :style="`font-weight:700;color:${row.status==='shortage'?'var(--el-color-danger)':'var(--el-color-warning)'}`">{{ row.qty }}</span></template>
            </el-table-column>
            <el-table-column prop="safety" label="安全库存" width="80" align="center" />
            <el-table-column label="状态" width="70" align="center">
              <template #default="{row}">
                <el-tag :type="row.status==='shortage'?'danger':'warning'" size="small">{{ row.status==='shortage'?'缺货':'预警' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="70" align="center">
              <template #default="{row}">
                <el-button size="small" text type="primary" @click="$router.push('/purchase/requisitions')">补货</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>

    <!-- Department Performance -->
    <el-card>
      <template #header><CardHeader title="部门业绩概览" subtitle="本月KPI完成率" /></template>
      <el-row :gutter="12">
        <el-col :span="4" v-for="dept in deptPerf" :key="dept.name">
          <div class="dept-card">
            <div class="dept-name">{{ dept.name }}</div>
            <div class="dept-pct" :style="`color:${dept.color}`">{{ dept.pct }}</div>
            <el-progress :percentage="parseInt(dept.pct)" :color="dept.color" :show-text="false" :stroke-width="6" style="margin:8px 0" />
            <div class="dept-note">{{ dept.note }}</div>
          </div>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import * as echarts from 'echarts'
import dayjs from 'dayjs'
import { useAuthStore } from '@/stores/auth'
import { fmt } from '@/utils/format'
import CardHeader from '@/components/common/CardHeader.vue'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()
const lineEl = ref()
const showQuickCreate = ref(false)
const today = dayjs().format('YYYY年MM月DD日 dddd')
const greeting = computed(() => {
  const h = new Date().getHours()
  return h < 9 ? '早上好，新的一天开始了！' : h < 12 ? '上午好，工作顺利！' : h < 14 ? '中午好，注意休息！' : h < 18 ? '下午好，继续加油！' : '晚上好，辛苦了！'
})

const kpiCards = [
  { icon:'💰', label:'本月营收', value:'¥238万', change:'+18.5%', trend:'up', bg:'rgba(79,142,247,.15)', path:'/bi' },
  { icon:'📦', label:'本月订单', value:'186笔', change:'+12.3%', trend:'up', bg:'rgba(34,197,94,.15)', path:'/crm/sales-orders' },
  { icon:'👥', label:'在职员工', value:'248人', change:'-2', trend:'down', bg:'rgba(168,85,247,.15)', path:'/hrm/employees' },
  { icon:'✅', label:'待审批', value:'3项', change:'需处理', trend:'down', bg:'rgba(245,158,11,.15)', path:'/workflow/approval' },
]

const pendingItems = ref([
  { id:1, type:'采购申请', applicant:'陈强', amount:'¥15,800', date:'2024-01-25', urgent:true },
  { id:2, type:'费用报销', applicant:'张伟', amount:'¥3,200', date:'2024-01-24', urgent:false },
  { id:3, type:'请假申请', applicant:'王磊', amount:'', date:'2024-01-23', urgent:false },
])

const recentOrders = [
  { order_no:'SO-2024-0001', customer:'华为技术', amount:128000, status:'shipped' },
  { order_no:'SO-2024-0002', customer:'腾讯科技', amount:68000, status:'approved' },
  { order_no:'SO-2024-0003', customer:'比亚迪', amount:380000, status:'pending' },
  { order_no:'SO-2024-0004', customer:'小米科技', amount:45000, status:'completed' },
]

const alertStock = [
  { name:'NVIDIA RTX 4090 显卡', qty:8, safety:15, status:'warning' },
  { name:'WD 4TB NVMe 固态硬盘', qty:3, safety:20, status:'shortage' },
]

const deptPerf = [
  { name:'销售部', pct:'92%', color:'#22c55e', note:'¥2,380,000' },
  { name:'采购部', pct:'78%', color:'#4f8ef7', note:'¥1,120,000' },
  { name:'财务部', pct:'88%', color:'#14b8a6', note:'结账准时' },
  { name:'技术部', pct:'65%', color:'#f59e0b', note:'项目交付' },
  { name:'人事部', pct:'80%', color:'#a855f7', note:'招聘完成' },
  { name:'仓储部', pct:'55%', color:'#ef4444', note:'周转提升' },
]

function approve(item) { pendingItems.value = pendingItems.value.filter(i=>i.id!==item.id); ElMessage.success('审批已通过') }
function reject(item)  { pendingItems.value = pendingItems.value.filter(i=>i.id!==item.id); ElMessage.warning('已退回申请') }

onMounted(() => {
  const chart = echarts.init(lineEl.value)
  chart.setOption({
    backgroundColor:'transparent',
    tooltip:{ trigger:'axis', backgroundColor:'#1e2535', borderColor:'#2a3548', textStyle:{color:'#e8eaf0'} },
    grid:{ left:40, right:20, top:10, bottom:30 },
    xAxis:{ type:'category', data:['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'], axisLine:{lineStyle:{color:'#2a3548'}}, axisLabel:{color:'#6b7591'} },
    yAxis:{ type:'value', splitLine:{lineStyle:{color:'#2a3548'}}, axisLabel:{color:'#6b7591'} },
    series:[
      { name:'营收', type:'line', data:[85,112,98,136,145,128,165,142,178,190,210,238], smooth:true, lineStyle:{width:2.5}, areaStyle:{opacity:.12}, itemStyle:{color:'#4f8ef7'} },
      { name:'利润', type:'line', data:[23,34,27,41,43,37,50,44,56,59,64,70], smooth:true, areaStyle:{opacity:.12}, itemStyle:{color:'#22c55e'} },
    ]
  })
  window.addEventListener('resize', () => chart.resize())
})
</script>

<style scoped lang="scss">
.dashboard { max-width:100%; }
.welcome-bar { display:flex; align-items:center; justify-content:space-between; margin-bottom:20px;
  h2 { font-size:20px; font-weight:700; margin:0 0 4px; }
  p { color:var(--el-text-color-secondary); font-size:13px; margin:0; }
}
.mb-4 { margin-bottom:16px; }
.kpi-card { cursor:pointer; transition:all .2s;
  &:hover { transform:translateY(-2px); box-shadow:0 8px 24px rgba(0,0,0,.15); }
}
.kpi-top { display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; }
.kpi-icon { width:40px; height:40px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:18px; }
.kpi-val { font-size:26px; font-weight:700; margin-bottom:6px; }
.kpi-lbl { font-size:12px; color:var(--el-text-color-secondary); }
.todo-item { display:flex; align-items:center; gap:10px; padding:10px 0; border-bottom:1px solid var(--el-border-color);
  &:last-child { border-bottom:none; }
}
.todo-dot { width:8px; height:8px; border-radius:50%; background:var(--el-color-primary); flex-shrink:0;
  &.urgent { background:var(--el-color-danger); }
}
.dept-card { background:var(--el-fill-color-light); border-radius:8px; padding:14px; }
.dept-name { font-size:13px; font-weight:600; margin-bottom:6px; }
.dept-pct { font-size:22px; font-weight:700; }
.dept-note { font-size:11px; color:var(--el-text-color-secondary); }
</style>
