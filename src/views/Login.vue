<template>
  <div class="login-page">
    <div class="login-left">
      <div class="brand">
        <div class="brand-icon">云</div>
        <h1>云智ERP</h1>
        <p>企业管理一体化平台</p>
      </div>
      <div class="features">
        <div class="feat-item" v-for="f in features" :key="f.icon">
          <span class="feat-icon">{{ f.icon }}</span>
          <div><strong>{{ f.title }}</strong><p>{{ f.desc }}</p></div>
        </div>
      </div>
    </div>
    <div class="login-right">
      <div class="login-box">
        <h2>欢迎登录</h2>
        <p class="sub">请输入您的账号密码</p>
        <el-form :model="form" :rules="rules" ref="formRef" size="large" @submit.prevent="handleLogin">
          <el-form-item prop="email">
            <el-input v-model="form.email" placeholder="邮箱账号" prefix-icon="User" clearable />
          </el-form-item>
          <el-form-item prop="password">
            <el-input v-model="form.password" type="password" placeholder="登录密码" prefix-icon="Lock" show-password />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="authStore.loading" class="login-btn" native-type="submit">
              {{ authStore.loading ? '登录中...' : '立即登录' }}
            </el-button>
          </el-form-item>
        </el-form>
        <div class="demo-accounts">
          <p>演示账号（点击快速填入）：</p>
          <div class="demo-list">
            <el-tag v-for="d in demos" :key="d.email" @click="fillDemo(d)" class="demo-tag" effect="plain">
              {{ d.label }}
            </el-tag>
          </div>
        </div>
      </div>
      <p class="copyright">© 2024 云智科技集团 · 版本 v2.8.1</p>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'

const router = useRouter()
const authStore = useAuthStore()
const formRef = ref()

const form = reactive({ email: '', password: '' })
const rules = {
  email: [{ required: true, message: '请输入邮箱', trigger: 'blur' },
          { type: 'email', message: '邮箱格式不正确', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' },
             { min: 6, message: '密码至少6位', trigger: 'blur' }]
}

const features = [
  { icon: '📊', title: '实时数据驾驶舱', desc: 'ECharts可视化，核心KPI一目了然' },
  { icon: '🔐', title: '企业级权限管控', desc: 'RBAC + RLS，数据安全有保障' },
  { icon: '🔀', title: '智能审批流引擎', desc: '可视化设计，多节点灵活配置' },
  { icon: '📡', title: '实时消息推送', desc: 'Supabase Realtime，零延迟通知' },
]

const demos = [
  { label: '超级管理员', email: 'admin@yunzhi.com', password: 'admin123456' },
  { label: '财务管理员', email: 'finance@yunzhi.com', password: 'finance123' },
  { label: '销售管理员', email: 'sales@yunzhi.com', password: 'sales123456' },
]

function fillDemo(d) {
  form.email = d.email
  form.password = d.password
}

async function handleLogin() {
  await formRef.value.validate()
  try {
    await authStore.signIn(form.email, form.password)
    ElMessage.success('登录成功，欢迎回来！')
    router.push('/')
  } catch (e) {
    ElMessage.error(e.message || '账号或密码错误')
  }
}
</script>

<style scoped lang="scss">
.login-page {
  display: flex; height: 100vh; overflow: hidden;
  background: #0f1117;
}
.login-left {
  flex: 1; background: linear-gradient(135deg,#1a2a4a,#0f1117);
  display: flex; flex-direction: column; justify-content: center;
  padding: 60px; border-right: 1px solid #2a3548;
}
.brand {
  margin-bottom: 48px;
  .brand-icon {
    width: 56px; height: 56px; border-radius: 14px;
    background: linear-gradient(135deg,#4f8ef7,#a855f7);
    display: flex; align-items: center; justify-content: center;
    font-size: 24px; font-weight: 700; color: #fff; margin-bottom: 16px;
  }
  h1 { font-size: 32px; font-weight: 700; color: #e8eaf0; margin: 0 0 8px; }
  p { color: #6b7591; font-size: 14px; margin: 0; }
}
.features { display: flex; flex-direction: column; gap: 24px; }
.feat-item {
  display: flex; gap: 14px; align-items: flex-start;
  .feat-icon { font-size: 24px; flex-shrink: 0; }
  strong { display: block; color: #e8eaf0; margin-bottom: 4px; }
  p { color: #6b7591; font-size: 13px; margin: 0; }
}
.login-right {
  width: 480px; display: flex; flex-direction: column;
  align-items: center; justify-content: center; padding: 60px 40px; position: relative;
}
.login-box {
  width: 100%;
  h2 { font-size: 28px; font-weight: 700; color: #e8eaf0; margin: 0 0 8px; }
  .sub { color: #6b7591; margin-bottom: 32px; }
}
.login-btn { width: 100%; height: 48px; font-size: 16px; }
.demo-accounts {
  margin-top: 24px; padding-top: 20px; border-top: 1px solid #2a3548;
  p { font-size: 12px; color: #6b7591; margin-bottom: 8px; }
  .demo-list { display: flex; gap: 8px; flex-wrap: wrap; }
  .demo-tag { cursor: pointer; }
}
.copyright { position: absolute; bottom: 24px; font-size: 12px; color: #3a4860; }
</style>
