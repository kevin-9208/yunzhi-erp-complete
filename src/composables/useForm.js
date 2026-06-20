import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'

export function useForm(defaultData = {}, submitFn) {
  const formRef = ref()
  const loading = ref(false)
  const formData = reactive({ ...defaultData })
  const visible = ref(false)
  const isEdit = ref(false)
  const editId = ref(null)

  function open(data = null) {
    isEdit.value = !!data
    editId.value = data?.id || null
    Object.assign(formData, { ...defaultData, ...(data || {}) })
    visible.value = true
  }

  function close() { visible.value = false; formRef.value?.resetFields() }

  async function submit() {
    await formRef.value.validate()
    loading.value = true
    try {
      const payload = { ...formData }
      await submitFn(payload, isEdit.value, editId.value)
      ElMessage.success(isEdit.value ? '修改成功' : '创建成功')
      close()
      return true
    } catch (e) {
      ElMessage.error(e.message || '操作失败')
      return false
    } finally {
      loading.value = false
    }
  }

  return { formRef, loading, formData, visible, isEdit, open, close, submit }
}
