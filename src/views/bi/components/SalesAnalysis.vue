<template>
  <div>
    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="k in kpis" :key="k.label">
        <div class="mini-kpi">
          <div class="mk-value" :style="`color:${k.color}`">{{ k.value }}</div>
          <div class="mk-label">{{ k.label }}</div>
          <div class="mk-change">{{ k.change }}</div>
        </div>
      </el-col>
    </el-row>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px">
      <div>
        <div style="font-weight:600;margin-bottom:12px">大区销售分布</div>
        <div v-for="r in regions" :key="r.name" style="margin-bottom:10px">
          <div style="display:flex;justify-content:space-between;font-size:12px;margin-bottom:4px">
            <span>{{ r.name }}</span><span style="font-weight:600">{{ r.amount }} · {{ r.pct }}%</span>
          </div>
          <el-progress :percentage="r.pct" :color="r.color" :show-text="false" :stroke-width="6" />
        </div>
      </div>
      <div>
        <div style="font-weight:600;margin-bottom:12px">销售漏斗</div>
        <div v-for="f in funnel" :key="f.stage" class="funnel-row">
          <span style="width:80px;font-size:12px;color:var(--el-text-color-secondary)">{{ f.stage }}</span>
          <div style="flex:1;height:22px;background:var(--el-fill-color);border-radius:3px;overflow:hidden">
            <div :style="`width:${f.pct}%;height:100%;background:${f.color};border-radius:3px`"></div>
          </div>
          <span style="width:40px;text-align:right;font-weight:600;font-size:12px">{{ f.count }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const kpis = [
  { label:'本月销售额', value:'¥2,380,000', change:'+18.5% ↑', color:'#4f8ef7' },
  { label:'订单数量',   value:'186笔',      change:'+12.3% ↑', color:'#22c55e' },
  { label:'平均订单额', value:'¥12,796',    change:'+5.4% ↑',  color:'#14b8a6' },
  { label:'客户成交率', value:'68.2%',       change:'+3.1% ↑',  color:'#a855f7' },
]
const regions = [
  { name:'华东', amount:'¥980,000', pct:41, color:'#4f8ef7' },
  { name:'华南', amount:'¥680,000', pct:29, color:'#22c55e' },
  { name:'华北', amount:'¥520,000', pct:22, color:'#a855f7' },
  { name:'西南', amount:'¥200,000', pct:8,  color:'#f59e0b' },
]
const funnel = [
  { stage:'线索',     count:312, pct:100, color:'#4f8ef7' },
  { stage:'潜在客户', count:218, pct:70,  color:'#14b8a6' },
  { stage:'商机确认', count:156, pct:50,  color:'#22c55e' },
  { stage:'方案报价', count:98,  pct:31,  color:'#f59e0b' },
  { stage:'谈判签约', count:54,  pct:17,  color:'#f97316' },
  { stage:'成交',     count:32,  pct:10,  color:'#ef4444' },
]
</script>

<style scoped lang="scss">
.mini-kpi { background:var(--el-fill-color-light); border-radius:8px; padding:14px; text-align:center; }
.mk-value { font-size:22px; font-weight:700; }
.mk-label { font-size:12px; color:var(--el-text-color-secondary); margin:4px 0; }
.mk-change { font-size:11px; color:var(--el-color-success); }
.funnel-row { display:flex; align-items:center; gap:10px; margin-bottom:8px; }
</style>
