<template>
  <div>
    <PageHeader title="费用报销" :breadcrumb="['财务管理','费用报销']">
      <template #actions>
        <el-input v-model="keyword" placeholder="搜索申请人/编号" prefix-icon="Search" style="width:200px" clearable />
        <el-select v-model="filterStatus" placeholder="状态" clearable style="width:120px">
          <el-option label="待审批" value="submitted" />
          <el-option label="审批中" value="reviewing" />
          <el-option label="已通过" value="approved" />
          <el-option label="已退回" value="rejected" />
        </el-select>
        <el-button type="primary" icon="Plus" @click="openForm()">提交报销</el-button>
      </template>
    </PageHeader>

    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card style="text-align:center">
          <div style="font-size:20px;font-weight:700" :style="`color:${s.color}`">{{ s.value }}</div>
          <div style="font-size:12px;color:var(--el-text-color-secondary);margin-top:4px">{{ s.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card>
      <el-table :data="filteredExpenses" stripe>
        <el-table-column prop="report_no" label="申请编号" width="130">
          <template #default="{row}"><span style="color:var(--el-color-primary);font-family:monospace">{{ row.report_no }}</span></template>
        </el-table-column>
        <el-table-column prop="emp_name" label="申请人" width="90">
          <template #default="{row}">
            <div style="display:flex;align-items:center;gap:6px">
              <el-avatar :size="24">{{ row.emp_name[0] }}</el-avatar>{{ row.emp_name }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="type" label="费用类型" width="100">
          <template #default="{row}"><el-tag size="small" type="info">{{ row.type }}</el-tag></template>
        </el-table-column>
        <el-table-column label="金额" width="120" align="right">
          <template #default="{row}"><span style="font-weight:700;font-size:15px">{{ fmt.money(row.amount) }}</span></template>
        </el-table-column>
        <el-table-column prop="occur_date" label="发生日期" width="110" />
        <el-table-column prop="dept" label="部门" width="90" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{row}">
            <el-tag :type="statusMap[row.status]?.type" size="small">{{ statusMap[row.status]?.label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right" align="center">
          <template #default="{row}">
            <el-button size="small" text type="primary" @click="viewDetail(row)">详情</el-button>
            <el-button v-if="row.status==='submitted'" size="small" text type="success" @click="approve(row)">审批</el-button>
            <el-button v-if="row.status==='submitted'" size="small" text type="danger" @click="reject(row)">退回</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Expense Form Dialog -->
    <el-dialog v-model="formVisible" title="提交费用报销" width="600px" align-center>
      <el-form :model="form" label-width="90px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="费用类型" required>
              <el-select v-model="form.type" style="width:100%">
                <el-option v-for="t in expenseTypes" :key="t" :label="t" :value="t" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="报销金额" required>
              <el-input-number v-model="form.amount" :min="0" :precision="2" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="发生日期" required>
              <el-date-picker v-model="form.occur_date" type="date" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="所属部门">
              <el-select v-model="form.dept" style="width:100%">
                <el-option v-for="d in deptList" :key="d" :label="d" :value="d" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="费用说明">
              <el-input v-model="form.desc" type="textarea" :rows="3" placeholder="请详细描述费用发生的事由及用途..." />
            </el-form-item>
          </el-col>
        </el-row>
        <!-- File Upload Area -->
        <el-form-item label="上传凭证">
          <el-upload drag action="#" :auto-upload="false" multiple accept=".jpg,.jpeg,.png,.pdf">
            <el-icon :size="40"><UploadFilled /></el-icon>
            <div>拖拽文件到此处，或 <em>点击上传</em></div>
            <template #tip><div style="font-size:12px;color:var(--el-text-color-secondary)">支持 JPG / PNG / PDF，单文件不超过 10MB</div></template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible=false">取消</el-button>
        <el-button type="primary" @click="submitForm">提交申请</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { fmt } from '@/utils/format'
import PageHeader from '@/components/common/PageHeader.vue'

const keyword = ref('')
const filterStatus = ref(null)
const formVisible = ref(false)
const form = reactive({ type:'差旅费', amount:0, occur_date:null, dept:'', desc:'' })

const expenseTypes = ['差旅费','招待费','办公费用','培训费','其他费用']
const deptList = ['销售部','财务部','技术部','人事部','采购部']
const statusMap = {
  draft:{ label:'草稿', type:'info' }, submitted:{ label:'待审批', type:'warning' },
  reviewing:{ label:'审批中', type:'' }, approved:{ label:'已通过', type:'success' },
  rejected:{ label:'已退回', type:'danger' }, paid:{ label:'已报销', type:'success' }
}

const expenses = ref([
  { id:1, report_no:'EXP-2024-001', emp_name:'张伟', type:'差旅费', amount:3200, occur_date:'2024-01-25', dept:'销售部', status:'submitted' },
  { id:2, report_no:'EXP-2024-002', emp_name:'李娜', type:'招待费', amount:6800, occur_date:'2024-01-24', dept:'财务部', status:'approved' },
  { id:3, report_no:'EXP-2024-003', emp_name:'王磊', type:'办公费用', amount:1500, occur_date:'2024-01-23', dept:'技术部', status:'approved' },
  { id:4, report_no:'EXP-2024-004', emp_name:'刘芳', type:'差旅费', amount:2800, occur_date:'2024-01-22', dept:'人事部', status:'submitted' },
  { id:5, report_no:'EXP-2024-005', emp_name:'陈强', type:'其他费用', amount:850, occur_date:'2024-01-21', dept:'采购部', status:'rejected' },
])

const filteredExpenses = computed(() => expenses.value.filter(e => {
  if (keyword.value && !e.emp_name.includes(keyword.value) && !e.report_no.includes(keyword.value)) return false
  if (filterStatus.value && e.status !== filterStatus.value) return false
  return true
}))

const stats = computed(() => [
  { label:'本月报销总额', value: fmt.money(expenses.value.reduce((a,e)=>a+e.amount,0)), color:'var(--el-color-primary)' },
  { label:'已审批', value: fmt.money(expenses.value.filter(e=>e.status==='approved').reduce((a,e)=>a+e.amount,0)), color:'var(--el-color-success)' },
  { label:'待审批', value: expenses.value.filter(e=>e.status==='submitted').length + '笔', color:'var(--el-color-warning)' },
  { label:'已退回', value: expenses.value.filter(e=>e.status==='rejected').length + '笔', color:'var(--el-color-danger)' },
])

function openForm() { Object.assign(form, { type:'差旅费', amount:0, occur_date:null, dept:'', desc:'' }); formVisible.value = true }
function submitForm() { ElMessage.success('报销申请已提交，等待审批'); formVisible.value = false }
function viewDetail(row) { ElMessage.info(`查看报销单：${row.report_no}`) }
async function approve(row) {
  await ElMessageBox.confirm(`确认审批通过 ${row.emp_name} 的 ${fmt.money(row.amount)} 报销申请？`, '审批确认', { type: 'warning' })
  row.status = 'approved'; ElMessage.success('审批已通过')
}
async function reject(row) {
  await ElMessageBox.prompt('请输入退回原因', '退回报销', { inputPlaceholder: '退回原因...' })
  row.status = 'rejected'; ElMessage.warning('报销申请已退回')
}
</script>
