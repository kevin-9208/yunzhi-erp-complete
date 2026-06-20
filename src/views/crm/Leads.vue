<template>
  <div>
    <PageHeader title="商机看板" :breadcrumb="['销售CRM','商机看板']">
      <template #actions>
        <el-radio-group v-model="viewMode" size="small">
          <el-radio-button label="kanban">看板视图</el-radio-button>
          <el-radio-button label="table">列表视图</el-radio-button>
        </el-radio-group>
        <el-button type="primary" icon="Plus" @click="showForm=true">新建商机</el-button>
      </template>
    </PageHeader>

    <!-- Kanban View -->
    <div v-if="viewMode==='kanban'" class="kanban-board">
      <div v-for="stage in stages" :key="stage.key" class="kanban-col">
        <div class="kc-header">
          <span>{{ stage.label }}</span>
          <el-tag :type="stage.tagType" size="small">{{ getStageItems(stage.key).length }}</el-tag>
        </div>
        <div class="kc-body">
          <div v-for="item in getStageItems(stage.key)" :key="item.id" class="kc-card" @click="viewDetail(item)">
            <div class="kc-title">{{ item.title }}</div>
            <div class="kc-amount">{{ fmt.money(item.amount) }}</div>
            <div class="kc-meta">
              <el-avatar :size="20">{{ item.owner[0] }}</el-avatar>
              <span>{{ item.owner }}</span>
              <span class="kc-date">{{ item.date }}</span>
            </div>
            <div class="kc-prob">
              <el-progress :percentage="item.probability" :stroke-width="4" :show-text="false" :color="stage.color" />
              <span style="font-size:10px;color:var(--el-text-color-placeholder)">{{ item.probability }}%成交概率</span>
            </div>
          </div>
          <el-button text size="small" style="width:100%;margin-top:6px" icon="Plus" @click="addToStage(stage.key)">添加</el-button>
        </div>
      </div>
    </div>

    <!-- Table View -->
    <el-card v-else>
      <el-table :data="opportunities" stripe>
        <el-table-column prop="title" label="商机名称" min-width="180" show-overflow-tooltip />
        <el-table-column prop="customer" label="客户" width="130" />
        <el-table-column label="金额" width="130" align="right"><template #default="{row}"><span style="font-weight:700;color:var(--el-color-primary)">{{ fmt.money(row.amount) }}</span></template></el-table-column>
        <el-table-column label="阶段" width="110" align="center">
          <template #default="{row}">
            <el-tag :type="stages.find(s=>s.key===row.stage)?.tagType" size="small">{{ stages.find(s=>s.key===row.stage)?.label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="probability" label="成交概率" width="130">
          <template #default="{row}"><el-progress :percentage="row.probability" :stroke-width="6" /></template>
        </el-table-column>
        <el-table-column prop="owner" label="负责人" width="90" />
        <el-table-column prop="date" label="预计日期" width="110" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{row}">
            <el-button size="small" text type="primary" @click="viewDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- New Opportunity Dialog -->
    <el-dialog v-model="showForm" title="新建商机" width="560px" align-center>
      <el-form :model="form" label-width="90px">
        <el-form-item label="商机名称" required><el-input v-model="form.title" /></el-form-item>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="关联客户"><el-select v-model="form.customer" style="width:100%" filterable><el-option v-for="c in customerList" :key="c" :label="c" :value="c" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="商机金额"><el-input-number v-model="form.amount" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="阶段"><el-select v-model="form.stage" style="width:100%"><el-option v-for="s in stages" :key="s.key" :label="s.label" :value="s.key" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="成交概率"><el-slider v-model="form.probability" :step="10" show-input /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="预计日期"><el-date-picker v-model="form.date" type="date" style="width:100%" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="商机描述"><el-input v-model="form.desc" type="textarea" :rows="3" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showForm=false">取消</el-button>
        <el-button type="primary" @click="submitForm">创建商机</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { fmt } from '@/utils/format'
import PageHeader from '@/components/common/PageHeader.vue'

const viewMode = ref('kanban')
const showForm = ref(false)
const form = reactive({ title:'', customer:'', amount:0, stage:'lead', probability:30, date:null, desc:'' })

const stages = [
  { key:'lead', label:'线索', tagType:'info', color:'#6b7591' },
  { key:'prospect', label:'潜在客户', tagType:'', color:'#4f8ef7' },
  { key:'qualified', label:'商机确认', tagType:'', color:'#14b8a6' },
  { key:'proposal', label:'方案报价', tagType:'warning', color:'#f59e0b' },
  { key:'negotiation', label:'谈判签约', tagType:'danger', color:'#f97316' },
  { key:'won', label:'已成交', tagType:'success', color:'#22c55e' },
]

const customerList = ['华为技术有限公司','腾讯科技','比亚迪','小米科技','阿里巴巴']

const opportunities = ref([
  { id:1, title:'某电商-服务器需求', customer:'京东科技', amount:80000, stage:'lead', probability:20, owner:'张伟', date:'2024-02-15' },
  { id:2, title:'广汽集团-IoT方案', customer:'广汽集团', amount:320000, stage:'prospect', probability:35, owner:'张伟', date:'2024-02-20' },
  { id:3, title:'中国银行-安防系统', customer:'中国银行', amount:580000, stage:'qualified', probability:50, owner:'李娜', date:'2024-03-01' },
  { id:4, title:'顺丰速运-仓储系统', customer:'顺丰速运', amount:280000, stage:'qualified', probability:55, owner:'张伟', date:'2024-02-28' },
  { id:5, title:'华为-服务器扩容', customer:'华为技术', amount:1280000, stage:'proposal', probability:70, owner:'张伟', date:'2024-02-10' },
  { id:6, title:'比亚迪-传感器采购', customer:'比亚迪', amount:380000, stage:'negotiation', probability:85, owner:'陈强', date:'2024-02-05' },
  { id:7, title:'腾讯-网络设备', customer:'腾讯科技', amount:68000, stage:'won', probability:100, owner:'张伟', date:'2024-01-25' },
  { id:8, title:'小米-存储设备', customer:'小米科技', amount:45000, stage:'won', probability:100, owner:'李娜', date:'2024-01-20' },
])

function getStageItems(stage) { return opportunities.value.filter(o => o.stage === stage) }
function viewDetail(item) { ElMessage.info(`商机详情：${item.title}`) }
function addToStage(stage) { form.stage = stage; showForm.value = true }
function submitForm() { ElMessage.success('商机已创建'); showForm.value = false }
</script>

<style scoped lang="scss">
.kanban-board { display:flex; gap:14px; overflow-x:auto; padding-bottom:8px; min-height:500px; }
.kanban-col { background:var(--el-fill-color-light); border:1px solid var(--el-border-color); border-radius:12px; min-width:220px; max-width:220px; display:flex; flex-direction:column; }
.kc-header { padding:12px 14px; border-bottom:1px solid var(--el-border-color); font-weight:600; font-size:13px; display:flex; align-items:center; justify-content:space-between; }
.kc-body { padding:10px; display:flex; flex-direction:column; gap:8px; flex:1; overflow-y:auto; }
.kc-card { background:var(--el-bg-color); border:1px solid var(--el-border-color); border-radius:8px; padding:12px; cursor:pointer; transition:all .15s;
  &:hover { border-color:var(--el-color-primary); box-shadow:0 4px 12px rgba(0,0,0,.15); transform:translateY(-1px); } }
.kc-title { font-size:12px; font-weight:500; margin-bottom:8px; }
.kc-amount { font-size:16px; font-weight:700; color:var(--el-color-primary); margin-bottom:8px; }
.kc-meta { display:flex; align-items:center; gap:6px; font-size:11px; color:var(--el-text-color-secondary); margin-bottom:8px; }
.kc-date { margin-left:auto; }
.kc-prob { display:flex; flex-direction:column; gap:2px; }
</style>
