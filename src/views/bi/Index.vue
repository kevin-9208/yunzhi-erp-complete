<template>
  <div class="bi-page">
    <PageHeader title="数据分析 BI" subtitle="实时业务数据可视化">
      <template #actions>
        <el-select v-model="period" style="width:120px">
          <el-option label="2024年" value="2024" />
          <el-option label="2023年" value="2023" />
        </el-select>
        <el-button icon="Download">导出报告</el-button>
        <el-button type="primary" icon="Refresh" @click="loadAll">刷新数据</el-button>
      </template>
    </PageHeader>

    <!-- KPI Cards -->
    <el-row :gutter="16" class="mb-16">
      <el-col :span="6" v-for="kpi in kpiCards" :key="kpi.label">
        <KpiCard v-bind="kpi" />
      </el-col>
    </el-row>

    <!-- Charts Row 1 -->
    <el-row :gutter="16" class="mb-16">
      <el-col :span="14">
        <el-card>
          <template #header>
            <CardHeader title="月度营收趋势" subtitle="2024年 · 万元">
              <el-radio-group v-model="revenueView" size="small">
                <el-radio-button label="monthly">月度</el-radio-button>
                <el-radio-button label="quarterly">季度</el-radio-button>
              </el-radio-group>
            </CardHeader>
          </template>
          <div ref="revenueChartEl" style="height:220px"></div>
        </el-card>
      </el-col>
      <el-col :span="10">
        <el-card>
          <template #header><CardHeader title="收入构成" subtitle="按业务类型" /></template>
          <div style="display:flex;align-items:center;gap:20px;padding:8px 0">
            <div ref="pieChartEl" style="height:200px;width:200px;flex-shrink:0"></div>
            <div style="flex:1">
              <div v-for="item in pieData" :key="item.name" style="margin-bottom:10px">
                <div style="display:flex;justify-content:space-between;font-size:12px;margin-bottom:4px">
                  <span style="display:flex;align-items:center;gap:6px">
                    <span :style="`width:8px;height:8px;background:${item.color};border-radius:50%;display:inline-block`"></span>
                    {{ item.name }}
                  </span>
                  <span style="font-weight:600">{{ item.value }}%</span>
                </div>
                <el-progress :percentage="item.value" :color="item.color" :show-text="false" :stroke-width="4" />
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Analysis Tabs -->
    <el-card class="mb-16">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="📊 销售分析" name="sales">
          <SalesAnalysis />
        </el-tab-pane>
        <el-tab-pane label="💰 财务分析" name="finance">
          <FinanceAnalysis />
        </el-tab-pane>
        <el-tab-pane label="📦 库存分析" name="inventory">
          <InventoryAnalysis />
        </el-tab-pane>
        <el-tab-pane label="👥 人力分析" name="hr">
          <HRAnalysis />
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- Rankings -->
    <el-row :gutter="16">
      <el-col :span="12">
        <el-card>
          <template #header><CardHeader title="销售人员排行" subtitle="本月业绩"></CardHeader></template>
          <div v-for="(item, idx) in salesRanking" :key="item.name" style="display:flex;align-items:center;gap:12px;padding:10px 0;border-bottom:1px solid var(--el-border-color)">
            <span style="font-size:18px;width:28px">{{ ['🥇','🥈','🥉','4️⃣','5️⃣'][idx] }}</span>
            <el-avatar :size="28">{{ item.name[0] }}</el-avatar>
            <div style="flex:1">
              <div style="font-size:13px;font-weight:500">{{ item.name }}</div>
              <el-progress :percentage="item.pct" :show-text="false" :stroke-width="4" style="margin-top:4px" />
            </div>
            <span style="font-weight:700;font-size:14px">{{ fmt.money(item.amount) }}</span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header><CardHeader title="客户增长趋势" subtitle="新增 vs 流失"></CardHeader></template>
          <div ref="growthChartEl" style="height:260px"></div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { fmt } from '@/utils/format'
import { COLORS } from '@/composables/useChart'
import PageHeader from '@/components/common/PageHeader.vue'
import KpiCard from '@/components/common/KpiCard.vue'
import CardHeader from '@/components/common/CardHeader.vue'
import SalesAnalysis from './components/SalesAnalysis.vue'
import FinanceAnalysis from './components/FinanceAnalysis.vue'
import InventoryAnalysis from './components/InventoryAnalysis.vue'
import HRAnalysis from './components/HRAnalysis.vue'

const period = ref('2024')
const activeTab = ref('sales')
const revenueView = ref('monthly')
const revenueChartEl = ref()
const pieChartEl = ref()
const growthChartEl = ref()

const months = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月']
const salesData = [85,112,98,136,145,128,165,142,178,190,210,238]
const costData  = [62,78,71,95,102,91,115,98,122,131,146,168]
const profitData = salesData.map((v,i) => v - costData[i])

const kpiCards = [
  { icon:'💰', label:'年度营收', value:'¥2,380万', change:'+18.5%', trend:'up', color:'#4f8ef7' },
  { icon:'📦', label:'年度订单', value:'2,186笔', change:'+12.3%', trend:'up', color:'#22c55e' },
  { icon:'🎯', label:'新增客户', value:'186家', change:'+24.1%', trend:'up', color:'#14b8a6' },
  { icon:'📊', label:'综合利润率', value:'29.4%', change:'+2.1%', trend:'up', color:'#a855f7' },
]

const pieData = [
  { name:'主营业务', value:76, color:'#4f8ef7' },
  { name:'服务收入', value:16, color:'#22c55e' },
  { name:'其他收入', value:8,  color:'#f59e0b' },
]

const salesRanking = [
  { name:'张伟', amount:580000, pct:92 },
  { name:'赵华', amount:432000, pct:78 },
  { name:'孙磊', amount:321000, pct:65 },
  { name:'陈丽', amount:289000, pct:52 },
  { name:'王芳', amount:198000, pct:38 },
]

const chartBaseOpts = {
  backgroundColor: 'transparent',
  tooltip: { trigger:'axis', backgroundColor:'#1e2535', borderColor:'#2a3548', textStyle:{ color:'#e8eaf0' } },
  grid: { left:40, right:20, top:20, bottom:30 },
  xAxis: { type:'category', data: months, axisLine:{ lineStyle:{color:'#2a3548'} }, axisLabel:{color:'#6b7591'} },
  yAxis: { type:'value', splitLine:{ lineStyle:{color:'#2a3548'} }, axisLabel:{color:'#6b7591'} },
}

function initRevenueChart() {
  const chart = echarts.init(revenueChartEl.value)
  chart.setOption({
    ...chartBaseOpts,
    legend: { data:['营收','成本','利润'], textStyle:{color:'#9ba3b8'}, bottom:0 },
    series: [
      { name:'营收', type:'line', data:salesData, smooth:true, lineStyle:{width:2.5}, areaStyle:{opacity:.12}, itemStyle:{color:'#4f8ef7'} },
      { name:'成本', type:'line', data:costData,  smooth:true, lineStyle:{width:2,type:'dashed'}, itemStyle:{color:'#ef4444'} },
      { name:'利润', type:'line', data:profitData, smooth:true, areaStyle:{opacity:.12}, itemStyle:{color:'#22c55e'} },
    ]
  })
  window.addEventListener('resize', () => chart.resize())
}

function initPieChart() {
  const chart = echarts.init(pieChartEl.value)
  chart.setOption({
    backgroundColor:'transparent',
    tooltip:{ trigger:'item', backgroundColor:'#1e2535', borderColor:'#2a3548', textStyle:{color:'#e8eaf0'} },
    series:[{
      type:'pie', radius:['55%','80%'], center:['50%','50%'],
      data: pieData.map(d => ({ name:d.name, value:d.value, itemStyle:{color:d.color} })),
      label:{ show:false }, emphasis:{ scale:true }
    }]
  })
}

function initGrowthChart() {
  const chart = echarts.init(growthChartEl.value)
  chart.setOption({
    ...chartBaseOpts,
    legend:{ data:['新增客户','流失客户'], textStyle:{color:'#9ba3b8'}, bottom:0 },
    series:[
      { name:'新增客户', type:'bar', data:[12,18,15,22,28,19,24,31,26,35,28,42], itemStyle:{color:'#22c55e',borderRadius:[3,3,0,0]} },
      { name:'流失客户', type:'bar', data:[2,3,4,2,5,3,4,3,6,4,5,3], itemStyle:{color:'#ef4444',borderRadius:[3,3,0,0]} },
    ]
  })
  window.addEventListener('resize', () => chart.resize())
}

function loadAll() {
  nextTick(() => {
    initRevenueChart()
    initPieChart()
    initGrowthChart()
  })
}

onMounted(loadAll)
</script>

<style scoped lang="scss">
.bi-page { max-width: 100%; }
.mb-16 { margin-bottom: 16px; }
</style>
