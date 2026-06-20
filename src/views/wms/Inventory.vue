<template>
  <div>
    <PageHeader title="库存总览" :breadcrumb="['库存WMS','库存总览']">
      <template #actions>
        <el-input v-model="keyword" placeholder="搜索产品/SKU" prefix-icon="Search" style="width:200px" clearable />
        <el-select v-model="filterStatus" placeholder="库存状态" clearable style="width:120px">
          <el-option label="正常" value="normal" />
          <el-option label="预警" value="warning" />
          <el-option label="缺货" value="shortage" />
        </el-select>
        <el-button icon="Refresh" @click="load">刷新</el-button>
        <el-button icon="Search" @click="$router.push('/wms/stocktake')">库存盘点</el-button>
        <el-button type="primary" icon="Download" @click="$router.push('/wms/inbound')">⬇ 入库</el-button>
      </template>
    </PageHeader>

    <el-row :gutter="16" style="margin-bottom:16px">
      <el-col :span="6" v-for="s in stats" :key="s.label">
        <el-card style="text-align:center">
          <div style="font-size:22px;margin-bottom:6px">{{ s.icon }}</div>
          <div style="font-size:20px;font-weight:700" :style="`color:${s.color}`">{{ s.value }}</div>
          <div style="font-size:12px;color:var(--el-text-color-secondary);margin-top:4px">{{ s.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Alert Banner -->
    <el-alert v-if="alertItems.length" type="warning" :closable="false" style="margin-bottom:16px" show-icon>
      <template #title>库存预警：{{ alertItems.map(i=>i.name).join('、') }} 库存不足，请及时补货</template>
    </el-alert>

    <el-card>
      <el-table :data="filteredInventory" stripe v-loading="loading">
        <el-table-column prop="code" label="SKU编码" width="110" fixed>
          <template #default="{row}"><span style="color:var(--el-color-primary);font-family:monospace;font-size:12px">{{ row.code }}</span></template>
        </el-table-column>
        <el-table-column prop="name" label="产品名称" min-width="180" show-overflow-tooltip>
          <template #default="{row}"><span style="font-weight:500">{{ row.name }}</span></template>
        </el-table-column>
        <el-table-column prop="category" label="分类" width="90">
          <template #default="{row}"><el-tag size="small" type="info">{{ row.category }}</el-tag></template>
        </el-table-column>
        <el-table-column label="当前库存" width="130" align="center">
          <template #default="{row}">
            <div style="display:flex;align-items:center;gap:8px">
              <span :style="`font-weight:700;color:${row.status==='shortage'?'var(--el-color-danger)':row.status==='warning'?'var(--el-color-warning)':'inherit'}`">{{ row.qty }}</span>
              <el-progress :percentage="Math.min(100,Math.round(row.qty/row.safety*100))"
                :color="row.status==='shortage'?'#ef4444':row.status==='warning'?'#f59e0b':'#22c55e'"
                :show-text="false" :stroke-width="5" style="width:60px" />
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="safety" label="安全库存" width="90" align="center" />
        <el-table-column label="单价" width="110" align="right">
          <template #default="{row}">{{ fmt.money(row.price) }}</template>
        </el-table-column>
        <el-table-column label="库存金额" width="130" align="right">
          <template #default="{row}"><span style="font-weight:600">{{ fmt.money(row.qty * row.price) }}</span></template>
        </el-table-column>
        <el-table-column prop="warehouse" label="仓库" width="90" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{row}">
            <el-tag :type="row.status==='normal'?'success':row.status==='warning'?'warning':'danger'" size="small">
              {{ {normal:'正常',warning:'预警',shortage:'缺货'}[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="130" fixed="right" align="center">
          <template #default="{row}">
            <el-button v-if="row.status!=='normal'" size="small" text type="danger" @click="restock(row)">补货</el-button>
            <el-button size="small" text @click="showTxns(row)">流水</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import { useRouter } from 'vue-router'
import { fmt } from '@/utils/format'
import PageHeader from '@/components/common/PageHeader.vue'

const router = useRouter()
const loading = ref(false)
const keyword = ref('')
const filterStatus = ref(null)

const inventory = ref([
  { id:1, code:'SKU001', name:'Intel i9-13900K 处理器', category:'CPU', qty:45, safety:20, price:4299, status:'normal', warehouse:'A区' },
  { id:2, code:'SKU002', name:'NVIDIA RTX 4090 显卡', category:'GPU', qty:8, safety:15, price:12999, status:'warning', warehouse:'A区' },
  { id:3, code:'SKU003', name:'三星 DDR5 32G 内存条', category:'内存', qty:128, safety:50, price:699, status:'normal', warehouse:'B区' },
  { id:4, code:'SKU004', name:'WD 4TB NVMe 固态硬盘', category:'存储', qty:3, safety:20, price:2399, status:'shortage', warehouse:'B区' },
  { id:5, code:'SKU005', name:'ASUS Z790 主板', category:'主板', qty:32, safety:10, price:2999, status:'normal', warehouse:'C区' },
  { id:6, code:'SKU006', name:'海康威视 4K 摄像头', category:'监控', qty:156, safety:30, price:899, status:'normal', warehouse:'C区' },
])

const filteredInventory = computed(() => inventory.value.filter(i => {
  if (keyword.value && !i.name.toLowerCase().includes(keyword.value.toLowerCase()) && !i.code.includes(keyword.value)) return false
  if (filterStatus.value && i.status !== filterStatus.value) return false
  return true
}))

const alertItems = computed(() => inventory.value.filter(i => i.status !== 'normal'))

const stats = computed(() => [
  { icon:'📦', label:'在库品种', value: inventory.value.length + '种', color:'var(--el-color-primary)' },
  { icon:'💰', label:'库存总额', value: fmt.money(inventory.value.reduce((a,i)=>a+i.qty*i.price,0)), color:'var(--el-color-success)' },
  { icon:'⚠️', label:'预警品种', value: inventory.value.filter(i=>i.status==='warning').length + '种', color:'var(--el-color-warning)' },
  { icon:'❌', label:'缺货品种', value: inventory.value.filter(i=>i.status==='shortage').length + '种', color:'var(--el-color-danger)' },
])

function load() { loading.value = true; setTimeout(() => loading.value = false, 500) }
function restock(row) { ElMessage.info(`正在为 ${row.name} 创建补货申请...`); router.push('/purchase/requisitions') }
function showTxns(row) { ElMessage.info(`查看 ${row.name} 的库存流水`) }
</script>
