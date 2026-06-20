import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

export function useTable(fetchFn, { defaultPageSize = 20 } = {}) {
  const loading = ref(false)
  const tableData = ref([])
  const pagination = reactive({ page: 1, pageSize: defaultPageSize, total: 0 })
  const filters = reactive({})

  async function load(params = {}) {
    loading.value = true
    try {
      const result = await fetchFn({ ...filters, ...params, page: pagination.page, pageSize: pagination.pageSize })
      tableData.value = result.data || []
      pagination.total = result.total || 0
    } catch (e) {
      ElMessage.error(e.message || '加载失败')
    } finally {
      loading.value = false
    }
  }

  function handlePageChange(p) { pagination.page = p; load() }
  function handleSizeChange(s) { pagination.pageSize = s; pagination.page = 1; load() }
  function handleFilterChange(f) { Object.assign(filters, f); pagination.page = 1; load() }

  async function handleDelete(id, deleteFn, msg = '确定删除该记录？') {
    await ElMessageBox.confirm(msg, '警告', { type: 'warning' })
    loading.value = true
    try {
      await deleteFn(id)
      ElMessage.success('删除成功')
      load()
    } catch (e) {
      ElMessage.error(e.message || '删除失败')
    } finally {
      loading.value = false }
  }

  return { loading, tableData, pagination, filters, load, handlePageChange, handleSizeChange, handleFilterChange, handleDelete }
}
