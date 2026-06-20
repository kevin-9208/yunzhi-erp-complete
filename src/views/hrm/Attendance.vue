<template>
  <div>
    <PageHeader title="考勤管理" :breadcrumb="['人力资源','考勤管理']">
      <template #actions>
        <el-date-picker v-model="period" type="month" format="YYYY年MM月" value-format="YYYY-MM" style="width:150px" />
        <el-button icon="Download">导出报表</el-button>
        <el-button type="primary" @click="clockDialog=true">📍 打卡</el-button>
      </template>
    </PageHeader>
    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card class="stat-card"><div class="sv">{{ s.value }}</div><div class="sl">{{ s.label }}</div></el-card>
      </el-col>
    </el-row>
    <el-row :gutter="16">
      <el-col :span="14">
        <el-card>
          <template #header><CardHeader title="考勤日历" :subtitle="period" /></template>
          <div class="calendar-grid">
            <div class="cal-head" v-for="d in weekDays" :key="d">{{ d }}</div>
            <div class="cal-empty" v-for="n in leadingDays" :key="'e'+n"></div>
            <div
              v-for="day in daysInMonth" :key="day"
              class="cal-day" :class="getDayClass(day)"
              :title="getDayStatus(day)"
            >{{ day }}</div>
          </div>
          <div class="cal-legend">
            <span v-for="l in legend" :key="l.label" class="leg-item">
              <span :class="`leg-dot ${l.cls}`"></span>{{ l.label }}
            </span>
          </div>
        </el-card>
      </el-col>
      <el-col :span="10">
        <el-card>
          <template #header><CardHeader title="出勤排行" /></template>
          <div v-for="(emp, idx) in attendance" :key="emp.name" class="att-row">
            <span class="att-rank">{{ idx+1 }}</span>
            <el-avatar :size="28">{{ emp.name[0] }}</el-avatar>
            <div style="flex:1">
              <div style="font-size:13px;font-weight:500">{{ emp.name }}</div>
              <el-progress :percentage="emp.pct" :color="emp.color" :show-text="false" :stroke-width="4" style="margin-top:4px" />
            </div>
            <span :style="`font-weight:600;color:${emp.color}`">{{ emp.days }}/22</span>
          </div>
        </el-card>
      </el-col>
    </el-row>
    <el-dialog v-model="clockDialog" title="考勤打卡" width="360px" align-center>
      <div style="text-align:center;padding:20px">
        <div style="font-size:48px;margin-bottom:12px">⏰</div>
        <div style="font-size:36px;font-weight:700;margin-bottom:8px">{{ currentTime }}</div>
        <div style="color:var(--el-text-color-secondary);margin-bottom:20px">{{ today }}</div>
        <el-alert type="success" :closable="false" style="margin-bottom:16px">已上班打卡 09:02</el-alert>
        <el-button type="danger" size="large" style="width:100%" @click="clockOut">下班打卡</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import dayjs from 'dayjs'
import PageHeader from '@/components/common/PageHeader.vue'
import CardHeader from '@/components/common/CardHeader.vue'

const period = ref(dayjs().format('YYYY-MM'))
const clockDialog = ref(false)
const currentTime = ref(dayjs().format('HH:mm:ss'))
let timer

const weekDays = ['一','二','三','四','五','六','日']
const stats = [
  { label:'本月出勤', value:'22.5天' }, { label:'迟到次数', value:'2次' },
  { label:'早退次数', value:'0次' }, { label:'请假天数', value:'1.5天' }
]

const daysInMonth = computed(() => {
  const d = dayjs(period.value)
  return Array.from({ length: d.daysInMonth() }, (_,i) => i+1)
})
const leadingDays = computed(() => {
  const firstDay = dayjs(period.value+'-01').day()
  return Array.from({ length: firstDay === 0 ? 6 : firstDay - 1 })
})

const specialDays = { 3:'late', 8:'leave', 15:'leave', 20:'absent', 25:'normal' }
function getDayClass(day) {
  const d = dayjs(period.value+'-'+String(day).padStart(2,'0'))
  if (d.isAfter(dayjs())) return 'future'
  if (d.day() === 0 || d.day() === 6) return 'weekend'
  return specialDays[day] || 'normal'
}
function getDayStatus(day) {
  const m = { normal:'正常出勤', late:'迟到', leave:'请假', absent:'缺勤', weekend:'休息', future:'' }
  return m[getDayClass(day)] || ''
}

const legend = [
  { label:'正常', cls:'green' }, { label:'迟到', cls:'yellow' },
  { label:'请假', cls:'blue' }, { label:'缺勤', cls:'red' }
]

const attendance = [
  { name:'张伟', days:22, pct:100, color:'#22c55e' },
  { name:'李娜', days:21, pct:95, color:'#22c55e' },
  { name:'王磊', days:20, pct:91, color:'#4f8ef7' },
  { name:'刘芳', days:22, pct:100, color:'#22c55e' },
  { name:'陈强', days:19, pct:86, color:'#f59e0b' },
]

const today = computed(() => dayjs().format('YYYY年MM月DD日 dddd'))

function clockOut() { clockDialog.value = false }

onMounted(() => { timer = setInterval(() => { currentTime.value = dayjs().format('HH:mm:ss') }, 1000) })
onUnmounted(() => clearInterval(timer))
</script>

<style scoped lang="scss">
.stat-card { text-align:center; }
.sv { font-size:28px; font-weight:700; }
.sl { font-size:12px; color:var(--el-text-color-secondary); margin-top:4px; }
.calendar-grid { display:grid; grid-template-columns:repeat(7,1fr); gap:4px; }
.cal-head { text-align:center; font-size:11px; color:var(--el-text-color-placeholder); padding:4px 0; }
.cal-empty { }
.cal-day {
  text-align:center; border-radius:6px; padding:7px 2px; font-size:12px; cursor:default;
  &.normal { background:var(--el-color-success-light-9); color:var(--el-color-success); }
  &.late { background:var(--el-color-warning-light-9); color:var(--el-color-warning); }
  &.leave { background:var(--el-color-primary-light-9); color:var(--el-color-primary); }
  &.absent { background:var(--el-color-danger-light-9); color:var(--el-color-danger); }
  &.weekend { color:var(--el-text-color-placeholder); }
  &.future { color:var(--el-text-color-disabled); }
}
.cal-legend { display:flex; gap:12px; margin-top:12px; padding-top:12px; border-top:1px solid var(--el-border-color); }
.leg-item { display:flex; align-items:center; gap:4px; font-size:12px; color:var(--el-text-color-secondary); }
.leg-dot { width:8px; height:8px; border-radius:50%;
  &.green { background:var(--el-color-success); }
  &.yellow { background:var(--el-color-warning); }
  &.blue { background:var(--el-color-primary); }
  &.red { background:var(--el-color-danger); }
}
.att-row { display:flex; align-items:center; gap:10px; padding:10px 0; border-bottom:1px solid var(--el-border-color); }
.att-rank { width:20px; text-align:center; font-size:12px; color:var(--el-text-color-placeholder); }
</style>
