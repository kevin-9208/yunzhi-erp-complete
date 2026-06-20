<template>
  <div class="card-header-inner">
    <div>
      <span class="ch-title">{{ title }}</span>
      <span v-if="subtitle" class="ch-sub">{{ subtitle }}</span>
    </div>
    <div class="ch-actions"><slot /></div>
  </div>
</template>
<script setup>
defineProps({ title: String, subtitle: String })
</script>
<style scoped lang="scss">
.card-header-inner { display:flex; align-items:center; justify-content:space-between; }
.ch-title { font-weight:600; font-size:14px; }
.ch-sub { font-size:12px; color:var(--el-text-color-secondary); margin-left:8px; }
.ch-actions { display:flex; gap:8px; align-items:center; }
</style>
