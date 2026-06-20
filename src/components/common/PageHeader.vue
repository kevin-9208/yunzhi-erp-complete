<template>
  <div class="page-header">
    <div>
      <el-breadcrumb separator="/" v-if="breadcrumb.length" style="margin-bottom:6px">
        <el-breadcrumb-item v-for="b in breadcrumb" :key="b">{{ b }}</el-breadcrumb-item>
      </el-breadcrumb>
      <h2 class="page-title">{{ title }}</h2>
      <p v-if="subtitle" class="page-subtitle">{{ subtitle }}</p>
    </div>
    <div class="page-actions">
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup>
defineProps({ title: String, subtitle: String, breadcrumb: { type: Array, default: () => [] } })
</script>

<style scoped lang="scss">
.page-header {
  display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 20px;
}
.page-title { font-size: 20px; font-weight: 700; margin: 0; }
.page-subtitle { color: var(--el-text-color-secondary); font-size: 13px; margin: 4px 0 0; }
.page-actions { display: flex; gap: 8px; align-items: center; flex-shrink: 0; }
</style>
