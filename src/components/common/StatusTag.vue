<template>
  <el-tag :type="tagType" size="small" effect="plain">{{ label }}</el-tag>
</template>
<script setup>
import { computed } from 'vue'

const props = defineProps({ status: String, map: { type: Object, default: () => ({}) } })

const defaultMap = {
  active: { label:'在职', type:'success' }, resigned: { label:'离职', type:'danger' },
  draft: { label:'草稿', type:'info' }, pending: { label:'待审批', type:'warning' },
  approved: { label:'已审批', type:'success' }, completed: { label:'已完成', type:'success' },
  cancelled: { label:'已取消', type:'danger' }, shipped: { label:'已发货', type:'' },
  normal: { label:'正常', type:'success' }, warning: { label:'预警', type:'warning' },
  shortage: { label:'缺货', type:'danger' }, open: { label:'进行中', type:'' },
  closed: { label:'已关闭', type:'info' }, posted: { label:'已过账', type:'success' },
}

const merged = computed(() => ({ ...defaultMap, ...props.map }))
const config = computed(() => merged.value[props.status] || { label: props.status, type: 'info' })
const tagType = computed(() => config.value.type)
const label = computed(() => config.value.label)
</script>
