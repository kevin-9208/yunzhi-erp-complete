<template>
  <el-row :gutter="16">
    <el-col :span="6" v-for="k in kpis" :key="k.label">
      <div class="mini-kpi">
        <div class="mk-value" :style="`color:${k.color}`">{{ k.value }}</div>
        <div class="mk-label">{{ k.label }}</div>
      </div>
    </el-col>
    <el-col :span="12" style="margin-top:16px">
      <div style="font-weight:600;margin-bottom:12px">部门人数分布</div>
      <div v-for="d in depts" :key="d.name" style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
        <span :style="`width:8px;height:8px;background:${d.color};border-radius:50%;flex-shrink:0`"></span>
        <span style="width:70px;font-size:13px">{{ d.name }}</span>
        <div style="flex:1">
          <el-progress :percentage="Math.round(d.count/68*100)" :color="d.color" :show-text="false" :stroke-width="6" />
        </div>
        <span style="width:30px;text-align:right;font-weight:600">{{ d.count }}</span>
      </div>
    </el-col>
    <el-col :span="12" style="margin-top:16px">
      <div style="font-weight:600;margin-bottom:12px">招聘进度</div>
      <el-table :data="recruit" size="small">
        <el-table-column prop="pos" label="职位" />
        <el-table-column prop="dept" label="部门" width="80" />
        <el-table-column label="进度" width="120">
          <template #default="{ row }">
            <el-progress :percentage="Math.round(row.done/row.total*100)" :stroke-width="6" />
          </template>
        </el-table-column>
      </el-table>
    </el-col>
  </el-row>
</template>
<script setup>
const kpis = [
  { label:'在职员工', value:'248人', color:'#4f8ef7' },
  { label:'本季离职率', value:'3.2%', color:'#ef4444' },
  { label:'本月入职', value:'5人', color:'#22c55e' },
  { label:'平均出勤', value:'21.8天', color:'#a855f7' },
]
const depts = [
  { name:'销售部', count:68, color:'#4f8ef7' }, { name:'技术部', count:52, color:'#22c55e' },
  { name:'行政部', count:35, color:'#f59e0b' }, { name:'仓储部', count:28, color:'#f97316' },
  { name:'财务部', count:18, color:'#a855f7' }, { name:'采购部', count:15, color:'#14b8a6' },
  { name:'人事部', count:12, color:'#ef4444' }, { name:'管理层', count:20, color:'#6b7591' },
]
const recruit = [
  { pos:'高级前端工程师', dept:'技术部', done:4, total:8 },
  { pos:'销售经理',     dept:'销售部', done:3, total:5 },
  { pos:'财务专员',     dept:'财务部', done:6, total:10 },
  { pos:'仓库管理员',   dept:'仓储部', done:5, total:12 },
]
</script>
<style scoped lang="scss">
.mini-kpi { background:var(--el-fill-color-light); border-radius:8px; padding:14px; text-align:center; }
.mk-value { font-size:22px; font-weight:700; }
.mk-label { font-size:12px; color:var(--el-text-color-secondary); margin-top:4px; }
</style>
