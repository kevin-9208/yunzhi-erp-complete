<template>
  <el-row :gutter="16">
    <el-col :span="6" v-for="k in kpis" :key="k.label">
      <div class="mini-kpi">
        <div class="mk-value" :style="`color:${k.color}`">{{ k.value }}</div>
        <div class="mk-label">{{ k.label }}</div>
      </div>
    </el-col>
    <el-col :span="24" style="margin-top:16px">
      <el-table :data="items" size="small" stripe>
        <el-table-column prop="code" label="SKU" width="100" />
        <el-table-column prop="name" label="产品名称" min-width="180" show-overflow-tooltip />
        <el-table-column prop="qty" label="当前库存" width="100" align="center">
          <template #default="{ row }">
            <span :style="`font-weight:600;color:${row.status==='缺货'?'var(--el-color-danger)':row.status==='预警'?'var(--el-color-warning)':'inherit'}`">{{ row.qty }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="safety" label="安全库存" width="100" align="center" />
        <el-table-column label="库存比例" min-width="120">
          <template #default="{ row }">
            <el-progress :percentage="Math.min(100,Math.round(row.qty/row.safety*100))" :color="row.status==='缺货'?'#ef4444':row.status==='预警'?'#f59e0b':'#22c55e'" :show-text="false" :stroke-width="6" />
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status==='正常'?'success':row.status==='预警'?'warning':'danger'" size="small">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-col>
  </el-row>
</template>
<script setup>
const kpis = [
  { label:'库存总额', value:'¥8,920,000', color:'#4f8ef7' },
  { label:'库存周转率', value:'4.2次/年', color:'#22c55e' },
  { label:'预警品种', value:'1种', color:'#f59e0b' },
  { label:'呆滞库存', value:'¥320,000', color:'#ef4444' },
]
const items = [
  { code:'SKU001', name:'Intel i9-13900K 处理器', qty:45, safety:20, status:'正常' },
  { code:'SKU002', name:'NVIDIA RTX 4090 显卡', qty:8, safety:15, status:'预警' },
  { code:'SKU003', name:'三星 DDR5 32G 内存', qty:128, safety:50, status:'正常' },
  { code:'SKU004', name:'WD 4TB NVMe 固态硬盘', qty:3, safety:20, status:'缺货' },
  { code:'SKU005', name:'ASUS Z790 主板', qty:32, safety:10, status:'正常' },
  { code:'SKU006', name:'海康威视 4K 摄像头', qty:156, safety:30, status:'正常' },
]
</script>
<style scoped lang="scss">
.mini-kpi { background:var(--el-fill-color-light); border-radius:8px; padding:14px; text-align:center; }
.mk-value { font-size:22px; font-weight:700; }
.mk-label { font-size:12px; color:var(--el-text-color-secondary); margin-top:4px; }
</style>
