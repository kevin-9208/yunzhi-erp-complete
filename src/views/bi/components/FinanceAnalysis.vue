<template>
  <el-row :gutter="16">
    <el-col :span="6" v-for="k in kpis" :key="k.label">
      <div class="mini-kpi">
        <div class="mk-value" :style="`color:${k.color}`">{{ k.value }}</div>
        <div class="mk-label">{{ k.label }}</div>
      </div>
    </el-col>
    <el-col :span="12" style="margin-top:16px">
      <div style="font-weight:600;margin-bottom:12px">收入来源结构</div>
      <div v-for="r in incomeBreakdown" :key="r.label" style="margin-bottom:10px">
        <div style="display:flex;justify-content:space-between;font-size:12px;margin-bottom:4px">
          <span>{{ r.label }}</span><span style="font-weight:600">{{ r.amount }} ({{ r.pct }}%)</span>
        </div>
        <el-progress :percentage="r.pct" :color="r.color" :show-text="false" :stroke-width="6" />
      </div>
    </el-col>
    <el-col :span="12" style="margin-top:16px">
      <div style="font-weight:600;margin-bottom:12px">支出明细</div>
      <div v-for="r in costBreakdown" :key="r.label" style="margin-bottom:10px">
        <div style="display:flex;justify-content:space-between;font-size:12px;margin-bottom:4px">
          <span>{{ r.label }}</span><span style="font-weight:600">{{ r.amount }} ({{ r.pct }}%)</span>
        </div>
        <el-progress :percentage="r.pct" :color="r.color" :show-text="false" :stroke-width="6" />
      </div>
    </el-col>
  </el-row>
</template>

<script setup>
const kpis = [
  { label:'月度收入', value:'¥2,380,000', color:'#22c55e' },
  { label:'月度支出', value:'¥1,680,000', color:'#ef4444' },
  { label:'月度利润', value:'¥700,000',   color:'#4f8ef7' },
  { label:'净利润率', value:'29.4%',       color:'#a855f7' },
]
const incomeBreakdown = [
  { label:'主营业务收入', amount:'¥1,820,000', pct:76, color:'#4f8ef7' },
  { label:'服务收入',     amount:'¥380,000',   pct:16, color:'#22c55e' },
  { label:'其他收入',     amount:'¥180,000',   pct:8,  color:'#f59e0b' },
]
const costBreakdown = [
  { label:'采购成本',   amount:'¥1,020,000', pct:61, color:'#ef4444' },
  { label:'人力成本',   amount:'¥420,000',   pct:25, color:'#f97316' },
  { label:'运营费用',   amount:'¥168,000',   pct:10, color:'#f59e0b' },
  { label:'其他',       amount:'¥72,000',    pct:4,  color:'#6b7591' },
]
</script>
<style scoped lang="scss">
.mini-kpi { background:var(--el-fill-color-light); border-radius:8px; padding:14px; text-align:center; }
.mk-value { font-size:22px; font-weight:700; }
.mk-label { font-size:12px; color:var(--el-text-color-secondary); margin-top:4px; }
</style>
