<template>
  <div>
    <PageHeader title="客户管理" :breadcrumb="['销售CRM','客户管理']">
      <template #actions>
        <el-input v-model="keyword" placeholder="搜索客户名称/联系人" prefix-icon="Search" style="width:220px" clearable />
        <el-select v-model="filterLevel" placeholder="客户级别" clearable style="width:110px">
          <el-option v-for="l in ['S','A','B','C']" :key="l" :label="l+'级'" :value="l" />
        </el-select>
        <el-button icon="Download">导出</el-button>
        <el-button type="primary" icon="Plus" @click="openForm()">新增客户</el-button>
      </template>
    </PageHeader>

    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card style="text-align:center">
          <div style="font-size:22px;font-weight:700;color:var(--el-color-primary)">{{ s.value }}</div>
          <div style="font-size:12px;color:var(--el-text-color-secondary);margin-top:4px">{{ s.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card>
      <el-table :data="filteredData" stripe>
        <el-table-column prop="code" label="编号" width="100"><template #default="{row}"><span style="font-family:monospace;color:var(--el-color-primary)">{{ row.code }}</span></template></el-table-column>
        <el-table-column prop="name" label="客户名称" min-width="180" show-overflow-tooltip>
          <template #default="{row}">
            <div style="font-weight:500">{{ row.name }}</div>
            <div style="font-size:11px;color:var(--el-text-color-secondary)">{{ row.phone }}</div>
          </template>
        </el-table-column>
        <el-table-column label="级别" width="80" align="center">
          <template #default="{row}">
            <el-tag :type="row.level==='S'?'danger':row.level==='A'?'warning':''" size="small">{{ row.level }}级</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="contact" label="联系人" width="100" />
        <el-table-column prop="industry" label="行业" width="100" />
        <el-table-column prop="contract_amount" label="合同额" width="130" align="right">
          <template #default="{row}"><span style="font-weight:600">{{ fmt.money(row.contract_amount) }}</span></template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template #default="{row}">
            <el-tag :type="row.status==='active'?'success':row.status==='follow'?'warning':'info'" size="small">
              {{ {active:'合作中',follow:'跟进中',potential:'潜在'}[row.status] || row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center" fixed="right">
          <template #default="{row}">
            <el-button size="small" text type="primary" @click="viewTimeline(row)">时间轴</el-button>
            <el-button size="small" text type="primary" @click="openForm(row)">编辑</el-button>
            <el-button size="small" text @click="addFollow(row)">跟进</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="formVisible" :title="isEdit?'编辑客户':'新增客户'" width="580px" align-center>
      <el-form :model="formData" label-width="80px">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="客户名称" required><el-input v-model="formData.name" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="客户级别"><el-select v-model="formData.level" style="width:100%"><el-option v-for="l in ['S','A','B','C']" :key="l" :label="l+'级'" :value="l" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系人"><el-input v-model="formData.contact" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="联系电话"><el-input v-model="formData.phone" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="行业"><el-select v-model="formData.industry" style="width:100%"><el-option v-for="i in ['科技','互联网','制造','金融','零售','汽车','医疗','其他']" :key="i" :label="i" :value="i" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="来源"><el-select v-model="formData.source" style="width:100%"><el-option v-for="s in ['线上推广','销售拜访','老客介绍','展会']" :key="s" :label="s" :value="s" /></el-select></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="地址"><el-input v-model="formData.address" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="formData.note" type="textarea" :rows="2" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="formVisible=false">取消</el-button>
        <el-button type="primary" @click="submitForm">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { fmt } from '@/utils/format'
import PageHeader from '@/components/common/PageHeader.vue'

const keyword = ref('')
const filterLevel = ref(null)
const formVisible = ref(false)
const isEdit = ref(false)
const formData = reactive({ name:'', level:'A', contact:'', phone:'', industry:'', source:'', address:'', note:'' })

const customers = ref([
  { id:1, code:'CRM001', name:'华为技术有限公司', contact:'刘德华', phone:'0755-28780808', industry:'科技', level:'S', status:'active', contract_amount:1280000 },
  { id:2, code:'CRM002', name:'腾讯科技（深圳）有限公司', contact:'马化腾', phone:'0755-86013388', industry:'互联网', level:'S', status:'active', contract_amount:980000 },
  { id:3, code:'CRM003', name:'阿里巴巴集团控股', contact:'张勇', phone:'0571-88588888', industry:'互联网', level:'A', status:'potential', contract_amount:450000 },
  { id:4, code:'CRM004', name:'比亚迪股份有限公司', contact:'王传福', phone:'0755-89888888', industry:'汽车', level:'S', status:'active', contract_amount:2100000 },
  { id:5, code:'CRM005', name:'小米科技有限责任公司', contact:'雷军', phone:'010-64783366', industry:'科技', level:'A', status:'follow', contract_amount:320000 },
])

const filteredData = computed(() => customers.value.filter(c => {
  const kw = keyword.value.toLowerCase()
  if (kw && !c.name.toLowerCase().includes(kw) && !c.contact.toLowerCase().includes(kw)) return false
  if (filterLevel.value && c.level !== filterLevel.value) return false
  return true
}))

const stats = computed(() => [
  { label:'客户总数', value: customers.value.length },
  { label:'合作中', value: customers.value.filter(c=>c.status==='active').length },
  { label:'跟进中', value: customers.value.filter(c=>c.status==='follow').length },
  { label:'总合同额', value: fmt.money(customers.value.reduce((a,c)=>a+c.contract_amount,0)) },
])

function openForm(row = null) {
  isEdit.value = !!row
  if (row) Object.assign(formData, row)
  else Object.assign(formData, { name:'', level:'A', contact:'', phone:'', industry:'', source:'', address:'', note:'' })
  formVisible.value = true
}

function submitForm() {
  ElMessage.success(isEdit.value ? '客户信息已更新' : '客户已添加')
  formVisible.value = false
}

function viewTimeline(row) { ElMessage.info(`查看 ${row.name} 的跟进时间轴`) }
function addFollow(row) { ElMessage.info(`添加跟进记录：${row.name}`) }
</script>
