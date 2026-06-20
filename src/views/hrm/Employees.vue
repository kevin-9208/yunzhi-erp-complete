<template>
  <div>
    <PageHeader title="员工档案" :breadcrumb="['人力资源','员工档案']">
      <template #actions>
        <el-input v-model="keyword" placeholder="搜索姓名/工号" prefix-icon="Search" style="width:200px" clearable @change="handleSearch" />
        <el-select v-model="filters.dept_id" placeholder="部门" clearable style="width:130px" @change="table.load">
          <el-option v-for="d in depts" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
        <el-select v-model="filters.status" placeholder="状态" clearable style="width:110px" @change="table.load">
          <el-option label="在职" value="active" />
          <el-option label="离职" value="resigned" />
          <el-option label="停职" value="suspended" />
        </el-select>
        <el-button icon="Download" @click="exportData">导出</el-button>
        <el-button type="primary" icon="Plus" @click="openForm()">新增员工</el-button>
      </template>
    </PageHeader>

    <!-- Summary chips -->
    <div class="summary-row">
      <el-tag effect="plain" type="">总人数：<strong>{{ pagination.total }}</strong></el-tag>
      <el-tag effect="plain" type="success">在职：<strong>{{ stats.active }}</strong></el-tag>
      <el-tag effect="plain" type="info">本月入职：<strong>{{ stats.newHires }}</strong></el-tag>
      <el-tag effect="plain" type="danger">本月离职：<strong>{{ stats.resigned }}</strong></el-tag>
    </div>

    <el-card>
      <el-table
        :data="tableData" v-loading="loading" stripe
        row-key="id" @row-click="viewDetail"
        style="width:100%" :row-style="{cursor:'pointer'}"
      >
        <el-table-column prop="emp_no" label="工号" width="100" fixed>
          <template #default="{ row }">
            <span style="color:var(--el-color-primary);font-family:monospace">{{ row.emp_no }}</span>
          </template>
        </el-table-column>
        <el-table-column label="姓名" width="120" fixed>
          <template #default="{ row }">
            <div style="display:flex;align-items:center;gap:8px">
              <el-avatar :size="28" :src="row.avatar_url">{{ row.name[0] }}</el-avatar>
              <span style="font-weight:500">{{ row.name }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="部门" prop="departments.name" width="100" />
        <el-table-column label="岗位" prop="positions.name" width="120" />
        <el-table-column prop="phone" label="手机" width="130">
          <template #default="{ row }"><span style="font-size:12px">{{ fmt.phone(row.phone) }}</span></template>
        </el-table-column>
        <el-table-column prop="hire_date" label="入职日期" width="110">
          <template #default="{ row }">{{ fmt.date(row.hire_date) }}</template>
        </el-table-column>
        <el-table-column prop="salary" label="薪资" width="110" align="right">
          <template #default="{ row }"><span style="font-weight:600">{{ fmt.money(row.salary) }}</span></template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <StatusTag :status="row.status" :map="{ active:{label:'在职',type:'success'}, resigned:{label:'离职',type:'danger'}, suspended:{label:'停职',type:'warning'} }" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right" align="center">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click.stop="openForm(row)">编辑</el-button>
            <el-button size="small" text type="info" @click.stop="viewDetail(row)">详情</el-button>
            <el-button v-if="row.status==='active'" size="small" text type="danger" @click.stop="handleResign(row)">离职</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        style="margin-top:16px;justify-content:flex-end;display:flex"
        v-model:current-page="pagination.page"
        v-model:page-size="pagination.pageSize"
        :total="pagination.total"
        :page-sizes="[20,50,100]"
        layout="total, sizes, prev, pager, next"
        @current-change="table.handlePageChange"
        @size-change="table.handleSizeChange"
      />
    </el-card>

    <!-- Employee Form Dialog -->
    <el-dialog v-model="formVisible" :title="isEdit?'编辑员工':'新增员工'" width="680px" align-center destroy-on-close>
      <el-form :model="formData" :rules="rules" ref="formRef" label-width="90px">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="工号" prop="emp_no"><el-input v-model="formData.emp_no" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="姓名" prop="name"><el-input v-model="formData.name" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="性别" prop="gender">
              <el-radio-group v-model="formData.gender">
                <el-radio label="男">男</el-radio>
                <el-radio label="女">女</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="出生日期"><el-date-picker v-model="formData.birth_date" type="date" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="手机号" prop="phone"><el-input v-model="formData.phone" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="邮箱" prop="email"><el-input v-model="formData.email" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="部门" prop="dept_id">
              <el-select v-model="formData.dept_id" style="width:100%">
                <el-option v-for="d in depts" :key="d.id" :label="d.name" :value="d.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="岗位" prop="position_id">
              <el-select v-model="formData.position_id" style="width:100%">
                <el-option v-for="p in positions" :key="p.id" :label="p.name" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="入职日期" prop="hire_date"><el-date-picker v-model="formData.hire_date" type="date" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="转正日期"><el-date-picker v-model="formData.regularize_date" type="date" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="基础薪资" prop="salary"><el-input-number v-model="formData.salary" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="试用薪资"><el-input-number v-model="formData.probation_salary" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="家庭住址"><el-input v-model="formData.address" type="textarea" :rows="2" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="formVisible=false">取消</el-button>
        <el-button type="primary" :loading="formLoading" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { employeesApi } from '@/api/employees'
import { supabase } from '@/supabase'
import { fmt } from '@/utils/format'
import PageHeader from '@/components/common/PageHeader.vue'
import StatusTag from '@/components/common/StatusTag.vue'

const loading = ref(false)
const tableData = ref([])
const pagination = reactive({ page: 1, pageSize: 20, total: 0 })
const filters = reactive({ dept_id: null, status: null })
const keyword = ref('')
const depts = ref([])
const positions = ref([])

const formVisible = ref(false)
const formLoading = ref(false)
const isEdit = ref(false)
const editId = ref(null)
const formRef = ref()
const formData = reactive({
  emp_no: '', name: '', gender: '男', birth_date: null, phone: '', email: '',
  dept_id: null, position_id: null, hire_date: null, regularize_date: null,
  salary: 0, probation_salary: 0, address: ''
})

const rules = {
  emp_no: [{ required: true, message: '请输入工号' }],
  name: [{ required: true, message: '请输入姓名' }],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }],
  dept_id: [{ required: true, message: '请选择部门' }],
  hire_date: [{ required: true, message: '请选择入职日期' }],
}

const stats = computed(() => ({
  active: tableData.value.filter(e => e.status === 'active').length,
  newHires: 2, resigned: 1
}))

const table = {
  async load() {
    loading.value = true
    try {
      const result = await employeesApi.list({ ...filters, page: pagination.page, pageSize: pagination.pageSize })
      tableData.value = result.data || []
      pagination.total = result.total || 0
    } catch (e) { ElMessage.error(e.message) }
    finally { loading.value = false }
  },
  handlePageChange(p) { pagination.page = p; table.load() },
  handleSizeChange(s) { pagination.pageSize = s; pagination.page = 1; table.load() }
}

async function loadDepts() {
  const { data } = await supabase.from('departments').select('id,name').eq('status','active')
  depts.value = data || []
}
async function loadPositions() {
  const { data } = await supabase.from('positions').select('id,name,dept_id')
  positions.value = data || []
}

function handleSearch() { pagination.page = 1; table.load() }

function openForm(row = null) {
  isEdit.value = !!row; editId.value = row?.id || null
  if (row) Object.assign(formData, { ...row, dept_id: row.dept_id, position_id: row.position_id })
  else Object.assign(formData, { emp_no:'', name:'', gender:'男', birth_date:null, phone:'', email:'', dept_id:null, position_id:null, hire_date:null, regularize_date:null, salary:0, probation_salary:0, address:'' })
  formVisible.value = true
}

async function submitForm() {
  await formRef.value.validate()
  formLoading.value = true
  try {
    if (isEdit.value) await employeesApi.update(editId.value, formData)
    else await employeesApi.create(formData)
    ElMessage.success(isEdit.value ? '修改成功' : '新增成功')
    formVisible.value = false
    table.load()
  } catch (e) { ElMessage.error(e.message) }
  finally { formLoading.value = false }
}

async function handleResign(row) {
  await ElMessageBox.confirm(`确认将 ${row.name} 办理离职？`, '离职确认', { type: 'warning' })
  await employeesApi.resign(row.id, new Date().toISOString().slice(0,10), '主动离职')
  ElMessage.success('已办理离职')
  table.load()
}

function viewDetail(row) { ElMessage.info(`查看员工详情：${row.name}`) }
function exportData() { ElMessage.success('导出成功，请查看下载文件') }

onMounted(() => { loadDepts(); loadPositions(); table.load() })
</script>

<style scoped lang="scss">
.summary-row { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:16px; }
</style>
