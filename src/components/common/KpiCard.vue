<template>
  <div class="kpi-card" :style="`--kpi-color:${color}`">
    <div class="kpi-top">
      <div class="kpi-icon">{{ icon }}</div>
      <el-tag :type="trend === 'up' ? 'success' : 'danger'" size="small" effect="plain">
        {{ trend === 'up' ? '↑' : '↓' }} {{ change }}
      </el-tag>
    </div>
    <div class="kpi-value">{{ value }}</div>
    <div class="kpi-label">{{ label }}</div>
  </div>
</template>

<script setup>
defineProps({ icon: String, label: String, value: String, change: String, trend: String, color: { default: '#4f8ef7' } })
</script>

<style scoped lang="scss">
.kpi-card {
  background: var(--el-bg-color); border: 1px solid var(--el-border-color);
  border-radius: 12px; padding: 18px 20px; transition: all .2s; cursor: default;
  &:hover { border-color: var(--el-color-primary); transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,.2); }
}
.kpi-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
.kpi-icon {
  width: 38px; height: 38px; border-radius: 8px; display: flex; align-items: center;
  justify-content: center; font-size: 18px;
  background: color-mix(in srgb, var(--kpi-color) 15%, transparent);
}
.kpi-value { font-size: 26px; font-weight: 700; line-height: 1; margin-bottom: 6px; }
.kpi-label { font-size: 12px; color: var(--el-text-color-secondary); }
</style>
