<template>
  <div>
    <PageHeader title="工作流设计器" :breadcrumb="['工作台','工作流设计器']">
      <template #actions>
        <el-select v-model="selectedTemplate" style="width:180px" @change="loadTemplate">
          <el-option v-for="t in templates" :key="t.id" :label="t.name" :value="t.id" />
        </el-select>
        <el-button icon="DocumentCopy" @click="saveAsTemplate">另存模板</el-button>
        <el-button type="primary" icon="Check" @click="saveFlow">保存流程</el-button>
      </template>
    </PageHeader>

    <el-row :gutter="16">
      <!-- Node Palette -->
      <el-col :span="4">
        <el-card>
          <template #header><span style="font-size:13px;font-weight:600">节点组件</span></template>
          <div v-for="node in nodePalette" :key="node.type" class="palette-node" :style="`border-color:${node.color};background:${node.bg}`"
            draggable="true" @dragstart="onDragStart(node)">
            <span style="font-size:18px">{{ node.icon }}</span>
            <div>
              <div style="font-size:12px;font-weight:600" :style="`color:${node.color}`">{{ node.label }}</div>
              <div style="font-size:10px;opacity:.7" :style="`color:${node.color}`">{{ node.desc }}</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- Canvas -->
      <el-col :span="14">
        <el-card style="min-height:560px">
          <template #header>
            <div style="display:flex;align-items:center;justify-content:space-between">
              <span style="font-weight:600">{{ currentTemplate?.name || '采购申请审批' }}</span>
              <div style="display:flex;gap:6px">
                <el-button size="small" text icon="ZoomIn">放大</el-button>
                <el-button size="small" text icon="ZoomOut">缩小</el-button>
                <el-button size="small" text icon="FullScreen">适应</el-button>
              </div>
            </div>
          </template>
          <div class="flow-canvas" @dragover.prevent @drop="onDrop">
            <div class="flow-column">
              <div v-for="(node, idx) in flowNodes" :key="node.id" class="flow-node-wrap">
                <div
                  class="flow-node" :class="{ selected: selectedNode?.id === node.id }"
                  :style="`border-color:${getNodeColor(node.type)};background:${getNodeBg(node.type)}`"
                  @click="selectNode(node)"
                >
                  <div class="fn-icon">{{ getNodeIcon(node.type) }}</div>
                  <div class="fn-body">
                    <div class="fn-title" :style="`color:${getNodeColor(node.type)}`">{{ node.label }}</div>
                    <div class="fn-sub">{{ node.sub || getNodeSub(node) }}</div>
                  </div>
                  <div class="fn-actions">
                    <el-button size="small" text :icon="'Delete'" @click.stop="removeNode(idx)" />
                  </div>
                </div>
                <div v-if="idx < flowNodes.length - 1" class="flow-connector">
                  <div class="fc-line"></div>
                  <div class="fc-arrow">▼</div>
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- Properties -->
      <el-col :span="6">
        <el-card>
          <template #header><span style="font-size:13px;font-weight:600">{{ selectedNode ? '节点属性' : '流程信息' }}</span></template>
          <div v-if="selectedNode">
            <el-form :model="selectedNode" label-width="80px" label-position="top" size="small">
              <el-form-item label="节点名称">
                <el-input v-model="selectedNode.label" />
              </el-form-item>
              <el-form-item label="审批人类型" v-if="selectedNode.type==='approval'">
                <el-select v-model="selectedNode.approver_type" style="width:100%">
                  <el-option label="指定人员" value="specific" />
                  <el-option label="直属上级" value="direct_manager" />
                  <el-option label="部门主管" value="dept_manager" />
                  <el-option label="角色" value="role" />
                </el-select>
              </el-form-item>
              <el-form-item label="指定角色" v-if="selectedNode.approver_type==='role'">
                <el-select v-model="selectedNode.role" style="width:100%">
                  <el-option v-for="r in roles" :key="r.value" :label="r.label" :value="r.value" />
                </el-select>
              </el-form-item>
              <el-form-item label="审批超时">
                <el-select v-model="selectedNode.timeout" style="width:100%">
                  <el-option label="24小时" value="24h" />
                  <el-option label="48小时" value="48h" />
                  <el-option label="72小时" value="72h" />
                </el-select>
              </el-form-item>
              <el-form-item label="超时处理">
                <el-select v-model="selectedNode.on_timeout" style="width:100%">
                  <el-option label="自动通过" value="approve" />
                  <el-option label="自动拒绝" value="reject" />
                  <el-option label="升级处理" value="escalate" />
                </el-select>
              </el-form-item>
              <div v-if="selectedNode.type==='condition'">
                <el-form-item label="条件字段">
                  <el-select v-model="selectedNode.field" style="width:100%">
                    <el-option label="金额" value="amount" />
                    <el-option label="部门" value="dept" />
                    <el-option label="申请人级别" value="level" />
                  </el-select>
                </el-form-item>
                <el-form-item label="判断值">
                  <el-input v-model="selectedNode.condition_value" placeholder="如: 10000" />
                </el-form-item>
              </div>
              <el-button type="primary" size="small" style="width:100%;margin-top:8px" @click="applyNodeConfig">应用配置</el-button>
            </el-form>
          </div>
          <div v-else>
            <el-form label-position="top" size="small">
              <el-form-item label="流程名称"><el-input v-model="flowName" /></el-form-item>
              <el-form-item label="适用类型">
                <el-select v-model="flowType" style="width:100%">
                  <el-option label="采购申请" value="purchase_req" />
                  <el-option label="费用报销" value="expense" />
                  <el-option label="请假申请" value="leave" />
                  <el-option label="合同审批" value="contract" />
                  <el-option label="用章申请" value="seal" />
                </el-select>
              </el-form-item>
              <el-form-item label="流程说明"><el-input v-model="flowDesc" type="textarea" :rows="3" /></el-form-item>
            </el-form>
          </div>
        </el-card>

        <!-- Template Library -->
        <el-card style="margin-top:16px">
          <template #header><span style="font-size:13px;font-weight:600">模板库</span></template>
          <div v-for="t in templates" :key="t.id" class="template-item" @click="loadTemplate(t.id)">
            <span style="font-size:18px">{{ t.icon }}</span>
            <div style="flex:1">
              <div style="font-size:12px;font-weight:500">{{ t.name }}</div>
              <div style="font-size:11px;color:var(--el-text-color-secondary)">使用 {{ t.used }} 次</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import PageHeader from '@/components/common/PageHeader.vue'

const selectedTemplate = ref(1)
const selectedNode = ref(null)
const flowName = ref('采购申请审批')
const flowType = ref('purchase_req')
const flowDesc = ref('适用于所有采购申请的审批流程')

const templates = [
  { id:1, name:'采购申请审批', icon:'🛒', type:'purchase_req', used:125 },
  { id:2, name:'费用报销审批', icon:'🧾', type:'expense', used:89 },
  { id:3, name:'请假申请审批', icon:'🏖️', type:'leave', used:342 },
  { id:4, name:'合同审批流程', icon:'📝', type:'contract', used:45 },
  { id:5, name:'用章申请审批', icon:'🔖', type:'seal', used:78 },
]

const nodePalette = [
  { type:'start',     label:'发起节点', desc:'流程开始', icon:'🚀', color:'#4f8ef7', bg:'rgba(79,142,247,.12)' },
  { type:'approval',  label:'审批节点', desc:'指定审批人', icon:'👤', color:'#22c55e', bg:'rgba(34,197,94,.12)' },
  { type:'cc',        label:'抄送节点', desc:'通知抄送', icon:'📧', color:'#a855f7', bg:'rgba(168,85,247,.12)' },
  { type:'condition', label:'条件节点', desc:'分支条件', icon:'⚡', color:'#f59e0b', bg:'rgba(245,158,11,.12)' },
  { type:'parallel',  label:'并行节点', desc:'同时审批', icon:'🔀', color:'#14b8a6', bg:'rgba(20,184,166,.12)' },
  { type:'end',       label:'结束节点', desc:'流程完成', icon:'✅', color:'#22c55e', bg:'rgba(34,197,94,.12)' },
]

const roles = [
  { label:'超级管理员', value:'super_admin' }, { label:'财务总监', value:'finance' },
  { label:'人事主管', value:'hr' }, { label:'采购经理', value:'purchase' }, { label:'总经理', value:'ceo' }
]

const defaultFlow = [
  { id:'n1', type:'start',    label:'发起申请', sub:'采购人员', approver_type:'', timeout:'24h', on_timeout:'approve' },
  { id:'n2', type:'approval', label:'直属上级审批', sub:'自动匹配', approver_type:'direct_manager', timeout:'24h', on_timeout:'approve' },
  { id:'n3', type:'condition',label:'金额判断', sub:'amount >= 10000', field:'amount', condition_value:'10000' },
  { id:'n4', type:'approval', label:'财务总监审核', sub:'李娜', approver_type:'role', role:'finance', timeout:'48h', on_timeout:'escalate' },
  { id:'n5', type:'end',      label:'审批完成', sub:'自动通知申请人' },
]

const flowNodes = ref([...defaultFlow])

function getNodeColor(type) { return nodePalette.find(n=>n.type===type)?.color || '#6b7591' }
function getNodeBg(type)    { return nodePalette.find(n=>n.type===type)?.bg    || 'transparent' }
function getNodeIcon(type)  { return nodePalette.find(n=>n.type===type)?.icon  || '📄' }
function getNodeSub(node)   { return node.approver_type === 'direct_manager' ? '自动匹配上级' : node.sub || '' }

let dragNode = null
function onDragStart(node) { dragNode = node }
function onDrop(e) {
  if (!dragNode) return
  const newNode = { id: 'n'+Date.now(), ...dragNode, sub:'', approver_type:'direct_manager', timeout:'24h', on_timeout:'approve' }
  const endIdx = flowNodes.value.findIndex(n=>n.type==='end')
  if (endIdx > -1) flowNodes.value.splice(endIdx, 0, newNode)
  else flowNodes.value.push(newNode)
  dragNode = null
}
function selectNode(node) { selectedNode.value = node }
function removeNode(idx) { flowNodes.value.splice(idx, 1); selectedNode.value = null }
function applyNodeConfig() { ElMessage.success('节点配置已应用') }
function saveFlow() { ElMessage.success('工作流已保存') }
function saveAsTemplate() { ElMessage.success('已另存为流程模板') }
function loadTemplate(id) { selectedTemplate.value = id; flowNodes.value = [...defaultFlow]; selectedNode.value = null; ElMessage.success('模板已加载') }
const currentTemplate = ref(templates[0])
</script>

<style scoped lang="scss">
.palette-node {
  display:flex; align-items:center; gap:8px; padding:10px 12px; border:1px solid; border-radius:8px;
  margin-bottom:8px; cursor:grab; transition:all .15s;
  &:hover { transform:translateX(2px); box-shadow:0 4px 12px rgba(0,0,0,.15); }
  &:active { cursor:grabbing; }
}
.flow-canvas { min-height:460px; display:flex; align-items:flex-start; justify-content:center; padding:20px; }
.flow-column { display:flex; flex-direction:column; align-items:center; gap:0; }
.flow-node-wrap { display:flex; flex-direction:column; align-items:center; }
.flow-node {
  display:flex; align-items:center; gap:10px; border:2px solid; border-radius:10px;
  padding:12px 16px; width:280px; cursor:pointer; transition:all .15s; position:relative;
  &:hover { box-shadow:0 4px 16px rgba(0,0,0,.2); transform:translateY(-1px); }
  &.selected { box-shadow:0 0 0 3px rgba(79,142,247,.4); }
}
.fn-icon { font-size:20px; flex-shrink:0; }
.fn-body { flex:1; }
.fn-title { font-size:13px; font-weight:600; }
.fn-sub { font-size:11px; opacity:.7; margin-top:2px; }
.fn-actions { flex-shrink:0; }
.flow-connector { display:flex; flex-direction:column; align-items:center; }
.fc-line { width:2px; height:18px; background:var(--el-border-color); }
.fc-arrow { font-size:10px; color:var(--el-text-color-placeholder); margin-top:-4px; }
.template-item {
  display:flex; align-items:center; gap:8px; padding:8px 0; border-bottom:1px solid var(--el-border-color);
  cursor:pointer; transition:background .15s;
  &:hover { background:var(--el-fill-color); }
  &:last-child { border-bottom:none; }
}
</style>
