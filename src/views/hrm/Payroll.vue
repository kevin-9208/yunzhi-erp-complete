<template>
  <div>
    <PageHeader title="薪资管理" :breadcrumb="['人力资源','薪资管理']">
      <template #actions>
        <el-select v-model="period" style="width:140px">
          <el-option label="2024年1月" value="2024-01" />
          <el-option label="2023年12月" value="2023-12" />
        </el-select>
        <el-button icon="DataAnalysis">薪资报表</el-button>
        <el-button type="primary" icon="Money" @click="payAll">发放工资</el-button>
      </template>
    </PageHeader>
    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card style="text-align:center">
          <div style="font-size:24px;font-weight:700;color:var(--el-color-primary)">{{ s.value }}</div>
          <div style="font-size:12px;color:var(--el-text-color-secondary);margin-top:4px">{{ s.label }}</div>
        </el-card>
      </el-col>
    </el-row>
    <el-card>
      <template #header><CardHeader title="工资条列表"><el-tag type="success">已发放 {{ list.length }} 人</el-tag></CardHeader></template>
      <el-table :data="list" stripe>
        <el-table-column prop="emp_no" label="工号" width="90"><template #default="{row}"><span style="font-family:monospace;color:var(--el-color-primary)">{{ row.emp_no }}</span></template></el-table-column>
        <el-table-column label="姓名" width="90">
          <template #default="{row}">
            <div style="display:flex;align-items:center;gap:6px">
              <el-avatar :size="24">{{ row.name[0] }}</el-avatar>{{ row.name }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="dept" label="部门" width="90" />
        <el-table-column prop="base" label="基础工资" align="right" width="110"><template #default="{row}">{{ fmt.money(row.base) }}</template></el-table-column>
        <el-table-column label="绩效" align="right" width="100"><template #default="{row}"><span style="color:var(--el-color-success)">+{{ fmt.money(row.perf) }}</span></template></el-table-column>
        <el-table-column label="津贴" align="right" width="100"><template #default="{row}"><span style="color:var(--el-color-primary)">+{{ fmt.money(row.allow) }}</span></template></el-table-column>
        <el-table-column label="社保扣" align="right" width="100"><template #default="{row}"><span style="color:var(--el-color-danger)">-{{ fmt.money(row.soc) }}</span></template></el-table-column>
        <el-table-column label="个税" align="right" width="100"><template #default="{row}"><span style="color:var(--el-color-warning)">-{{ fmt.money(row.tax) }}</span></template></el-table-column>
        <el-table-column label="实发工资" align="right" width="120"><template #default="{row}"><span style="font-weight:700;font-size:15px">{{ fmt.money(row.net) }}</span></template></el-table-column>
        <el-table-column label="状态" width="90" align="center"><template #default><el-tag type="success" size="small">已发放</el-tag></template></el-table-column>
        <el-table-column label="操作" width="80" align="center"><template #default><el-button size="small" text type="primary">工资单</el-button></template></el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { fmt } from '@/utils/format'
import PageHeader from '@/components/common/PageHeader.vue'
import CardHeader from '@/components/common/CardHeader.vue'

const period = ref('2024-01')

const rawList = [
  { emp_no:'EMP001', name:'张伟', dept:'销售部', base:28000 },
  { emp_no:'EMP002', name:'李娜', dept:'财务部', base:32000 },
  { emp_no:'EMP003', name:'王磊', dept:'技术部', base:22000 },
  { emp_no:'EMP004', name:'刘芳', dept:'人事部', base:15000 },
  { emp_no:'EMP005', name:'陈强', dept:'采购部', base:18000 },
]

const list = computed(() => rawList.map(e => {
  const perf = Math.round(e.base * 0.2)
  const allow = Math.round(e.base * 0.1)
  const soc = Math.round(e.base * 0.105)
  const tax = Math.max(0, Math.round((e.base + perf) * 0.1 - 2520))
  return { ...e, perf, allow, soc, tax, net: e.base + perf + allow - soc - tax }
}))

const stats = computed(() => [
  { label:'薪资总额', value: fmt.money(list.value.reduce((a,e)=>a+e.net,0)) },
  { label:'发放人数', value: list.value.length + '人' },
  { label:'社保公积金', value: fmt.money(list.value.reduce((a,e)=>a+e.soc,0)) },
  { label:'代扣个税', value: fmt.money(list.value.reduce((a,e)=>a+e.tax,0)) },
])

async function payAll() {
  await ElMessageBox.confirm('确认发放本月全部工资？', '批量发放', { type: 'warning' })
  ElMessage.success('工资已批量发放，员工将收到短信通知')
}
</script>
