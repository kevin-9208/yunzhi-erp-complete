<template>
  <div>
    <PageHeader title="销售订单" :breadcrumb="['销售CRM','销售订单']">
      <template #actions>
        <el-input v-model="keyword" placeholder="搜索订单号/客户" prefix-icon="Search" style="width:200px" clearable />
        <el-select v-model="filterStatus" placeholder="状态" clearable style="width:120px">
          <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
        </el-select>
        <el-button type="primary" icon="Plus" @click="openForm()">新建订单</el-button>
      </template>
    </PageHeader>

    <!-- Flow Steps -->
    <div class="flow-bar">
      <div v-for="(step, idx) in flowSteps" :key="step" :class="['flow-step', idx < 2 ? 'done' : idx === 2 ? 'active' : '']">
        {{ idx < 2 ? '✓ ' : '' }}{{ step }}
      </div>
    </div>

    <el-card>
      <el-table :data="filteredOrders" stripe v-loading="loading">
        <el-table-column prop="order_no" label="订单号" width="150" fixed>
          <template #default="{row}"><span style="color:var(--el-color-primary);font-family:monospace">{{ row.order_no }}</span></template>
        </el-table-column>
        <el-table-column prop="customer" label="客户" min-width="150" show-overflow-tooltip />
        <el-table-column prop="product" label="产品" min-width="140" show-overflow-tooltip />
        <el-table-column prop="qty" label="数量" width="80" align="center" />
        <el-table-column label="金额" width="130" align="right">
          <template #default="{row}"><span style="font-weight:700">{{ fmt.money(row.amount) }}</span></template>
        </el-table-column>
        <el-table-column prop="date" label="下单日期" width="110" />
        <el-table-column label="状态" width="90" align="center">
          <template #default="{row}">
            <el-tag :type="statusMap[row.status]?.type" size="small">{{ statusMap[row.status]?.label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" fixed="right" align="center">
          <template #default="{row}">
            <el-button size="small" text type="primary">详情</el-button>
            <el-button v-if="row.status==='pending'" size="small" text type="success" @click="approve(row)">审批</el-button>
            <el-button v-if="row.status==='approved'" size="small" text type="warning" @click="ship(row)">发货</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:16px;justify-content:flex-end;display:flex"
        v-model:current-page="page" :page-size="10" :total="orders.length" layout="total, prev, pager, next" />
    </el-card>

    <el-dialog v-model="formVisible" title="新建销售订单" width="580px" align-center>
      <el-form :model="form" label-width="90px">
        <el-form-item label="客户" required><el-select v-model="form.customer" style="width:100%" filterable><el-option v-for="c in customerList" :key="c" :label="c" :value="c" /></el-select></el-form-item>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="产品"><el-input v-model="form.product" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="数量"><el-input-number v-model="form.qty" :min="1" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="单价"><el-input-number v-model="form.price" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="交货日期"><el-date-picker v-model="form.delivery_date" type="date" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="合计金额">
          <el-statistic :value="form.qty * form.price" prefix="¥" :precision="2" />
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="form.note" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="formVisible=false">取消</el-button>
        <el-button>保存草稿</el-button>
        <el-button type="primary" @click="submitOrder">提交审批</el-button>
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
const filterStatus = ref(null)
const page = ref(1)
const loading = ref(false)
const formVisible = ref(false)
const form = reactive({ customer:'', product:'', qty:1, price:0, delivery_date:null, note:'' })

const flowSteps = ['报价单','销售订单','审批','发货','收款','开票']
const statusOptions = [
  { label:'待审批', value:'pending' }, { label:'已审批', value:'approved' },
  { label:'已发货', value:'shipped' }, { label:'已完成', value:'completed' }, { label:'已取消', value:'cancelled' }
]
const statusMap = {
  draft:{ label:'草稿', type:'info' }, pending:{ label:'待审批', type:'warning' },
  approved:{ label:'已审批', type:'success' }, shipped:{ label:'已发货', type:'' },
  completed:{ label:'已完成', type:'success' }, cancelled:{ label:'已取消', type:'danger' }
}
const customerList = ['华为技术有限公司','腾讯科技','比亚迪','小米科技','阿里巴巴']

const orders = ref([
  { id:1, order_no:'SO-2024-0001', customer:'华为技术有限公司', product:'服务器配件', qty:50, amount:128000, date:'2024-01-15', status:'shipped' },
  { id:2, order_no:'SO-2024-0002', customer:'腾讯科技', product:'网络设备', qty:20, amount:68000, date:'2024-01-18', status:'approved' },
  { id:3, order_no:'SO-2024-0003', customer:'比亚迪股份有限公司', product:'工业传感器', qty:200, amount:380000, date:'2024-01-20', status:'pending' },
  { id:4, order_no:'SO-2024-0004', customer:'小米科技有限责任公司', product:'存储设备', qty:30, amount:45000, date:'2024-01-22', status:'completed' },
  { id:5, order_no:'SO-2024-0005', customer:'阿里巴巴集团', product:'路由器', qty:100, amount:92000, date:'2024-01-25', status:'shipped' },
])

const filteredOrders = computed(() => orders.value.filter(o => {
  if (keyword.value && !o.order_no.includes(keyword.value) && !o.customer.includes(keyword.value)) return false
  if (filterStatus.value && o.status !== filterStatus.value) return false
  return true
}))

function openForm() { formVisible.value = true }
function approve(row) { row.status = 'approved'; ElMessage.success(`订单 ${row.order_no} 已审批通过`) }
function ship(row) { row.status = 'shipped'; ElMessage.success(`订单 ${row.order_no} 已发货`) }
function submitOrder() { ElMessage.success('销售订单已提交审批'); formVisible.value = false }
</script>

<style scoped lang="scss">
.flow-bar { display:flex; align-items:center; gap:6px; margin-bottom:16px; flex-wrap:wrap; }
.flow-step {
  padding:6px 14px; border-radius:6px; font-size:12px; font-weight:500;
  background:var(--el-fill-color-light); color:var(--el-text-color-secondary); border:1px solid var(--el-border-color);
  &.active { background:var(--el-color-primary-light-9); color:var(--el-color-primary); border-color:var(--el-color-primary-light-5); }
  &.done { background:var(--el-color-success-light-9); color:var(--el-color-success); border-color:var(--el-color-success-light-5); }
}
</style>
