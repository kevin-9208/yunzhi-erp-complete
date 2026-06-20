# 云智ERP 部署文档

vercel部署地址: `https://yunzhi-erp-complete.vercel.app/`

## 一、技术栈

| 层级 | 技术 |
|------|------|
| 前端框架 | Vue 3.4 + Composition API |
| 语言 | JavaScript (ESNext) |
| 构建工具 | Vite 5 |
| 状态管理 | Pinia 2 |
| UI组件库 | Element Plus 2.5 |
| 图表 | ECharts 5 |
| 路由 | Vue Router 4 |
| 后端/数据库 | Supabase (PostgreSQL 15) |
| 认证 | Supabase Auth |
| 实时推送 | Supabase Realtime |
| 文件存储 | Supabase Storage |

---

## 二、Supabase 项目配置

### 1. 创建 Supabase 项目

1. 访问 https://supabase.com → New Project
2. 选择区域（推荐：ap-northeast-1 日本/ap-east-1 香港）
3. 设置数据库密码（请保存）

### 2. 执行数据库初始化 SQL

```bash
# 方法1：Supabase Dashboard → SQL Editor
# 复制 supabase/migrations/001_init.sql 全部内容执行

# 方法2：Supabase CLI
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```

### 3. 配置 Storage Bucket

在 Supabase Dashboard → Storage 创建以下 Bucket：

| Bucket 名 | 说明 | 访问控制 |
|-----------|------|---------|
| `erp-files` | 企业文件管理 | Private |
| `avatars` | 用户头像 | Public |
| `contracts` | 合同文档 | Private |
| `expense-receipts` | 报销凭证 | Private |

### 4. 配置 Realtime

Supabase Dashboard → Database → Replication
启用以下表的 Realtime：
- `notifications`
- `workflow_instances`
- `inventory`

### 5. 创建初始管理员账号

```sql
-- 在 Supabase Auth 中创建用户后执行：
INSERT INTO public.users (id, emp_id, name, email, role_id)
VALUES (
  'f76c9c01-12d6-4bab-93d4-de5813bae654',
  'EMP000',
  '超级管理员',
  'admin@yunzhi.com',
  (SELECT id FROM roles WHERE name = 'super_admin')
);
```

---

## 三、前端部署

### 本地开发

```bash
# 1. 安装依赖
npm install

# 2. 配置环境变量
cp .env.example .env.local
# 填入 Supabase URL 和 Anon Key

# 3. 启动开发服务器
npm run dev
# 访问 http://localhost:3000
```

### 生产构建

```bash
npm run build
# 产物在 dist/ 目录
```

### Vercel 部署（推荐）

```bash
# 安装 Vercel CLI
npm i -g vercel

# 部署
vercel --prod

# 配置环境变量
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY
```

vercel.json 配置：
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }],
  "headers": [{
    "source": "/(.*)",
    "headers": [
      { "key": "X-Frame-Options", "value": "DENY" },
      { "key": "X-Content-Type-Options", "value": "nosniff" }
    ]
  }]
}
```

### Nginx 部署

```nginx
server {
    listen 80;
    server_name your-erp.com;
    root /var/www/erp/dist;
    index index.html;

    # Gzip
    gzip on;
    gzip_types text/css application/javascript application/json;

    # Cache static assets
    location ~* \.(js|css|png|jpg|ico)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Docker 部署

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
docker build -t yunzhi-erp .
docker run -p 80:80 \
  -e VITE_SUPABASE_URL=https://xxx.supabase.co \
  -e VITE_SUPABASE_ANON_KEY=your-key \
  yunzhi-erp
```

---

## 四、Supabase Edge Functions

### 定时任务（库存预警）

```bash
# 创建 function
supabase functions new inventory-alert

# 部署
supabase functions deploy inventory-alert --no-verify-jwt

# 设置 CRON（每天8点）
supabase functions schedule inventory-alert "0 8 * * *"
```

`supabase/functions/inventory-alert/index.ts`:
```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Find items below safety stock
  const { data: alerts } = await supabase
    .from('inventory')
    .select('*, products(name), warehouses(name)')
    .filter('qty', 'lte', 'safety_qty')

  // Create notifications for warehouse managers
  for (const item of alerts || []) {
    await supabase.from('notifications').insert({
      type: 'warning',
      title: '库存预警',
      content: `${item.products.name} 库存不足（当前:${item.qty}，安全库存:${item.safety_qty}）`
    })
  }

  return new Response(JSON.stringify({ alerted: alerts?.length }))
})
```

### 工资自动计算 Function

```bash
supabase functions new payroll-calc
supabase functions deploy payroll-calc
# Schedule: 每月最后一天
supabase functions schedule payroll-calc "0 18 28-31 * *"
```

---

## 五、环境变量

```env
# .env.local (开发环境)
VITE_SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_APP_TITLE=云智ERP
VITE_APP_VERSION=2.8.1
VITE_APP_ENV=development

# .env.production (生产环境)
VITE_SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_APP_ENV=production
```

---

## 六、安全配置

### RLS 策略检查清单

- [x] users 表：用户只能读取自己，管理员可读全部
- [x] employees 表：HR 和管理员可管理，普通员工只能看自己
- [x] customers 表：销售只能看自己负责的客户
- [x] payroll 表：只有 HR 和本人能看
- [x] notifications 表：只能看自己的消息
- [x] audit_logs 表：只有管理员能看

### API 安全

```javascript
// 所有 Supabase 查询都通过 anon key
// 服务端操作（Edge Functions）使用 service_role key
// 永远不要在前端暴露 service_role key
```

---

## 七、性能优化

### 构建优化

vite.config.js 已配置手动 chunk 分割：
- `vue-vendor`: Vue 核心库
- `element-plus`: UI 组件库
- `echarts`: 图表库
- `supabase`: 后端客户端

### 数据库优化

- 所有外键字段已建立索引
- 全文搜索使用 GIN 索引 (`pg_trgm`)
- Realtime 仅开启必要的表

### 前端优化

- `keep-alive` 缓存最多 15 个页面组件
- ECharts 按需在组件内初始化
- Element Plus 按需自动导入（`unplugin-auto-import`）

---

## 八、项目结构总览

```
yunzhi-erp/
├── src/
│   ├── api/                 # Supabase API 封装
│   │   ├── base.js          # BaseApi 基类（含审计日志）
│   │   ├── employees.js     # HRM API
│   │   ├── crm.js           # CRM API
│   │   ├── finance.js       # 财务 API
│   │   ├── wms.js           # 仓储 API
│   │   └── workflow.js      # 审批流 API
│   ├── components/
│   │   ├── common/          # 通用组件
│   │   │   ├── PageHeader.vue
│   │   │   ├── KpiCard.vue
│   │   │   ├── CardHeader.vue
│   │   │   └── StatusTag.vue
│   │   └── layout/          # 布局组件
│   │       ├── MainLayout.vue
│   │       ├── SidebarLogo.vue
│   │       ├── SidebarMenu.vue
│   │       ├── TopBar.vue
│   │       ├── TabsBar.vue
│   │       └── NotificationDrawer.vue
│   ├── composables/         # Vue 组合式函数
│   │   ├── useTable.js      # 表格分页/筛选/删除
│   │   ├── useForm.js       # 表单 CRUD
│   │   ├── useChart.js      # ECharts 封装
│   │   └── usePermission.js # 权限判断
│   ├── stores/              # Pinia 状态管理
│   │   ├── auth.js          # 认证/用户信息
│   │   ├── app.js           # 应用状态/标签页
│   │   └── notification.js  # 消息通知
│   ├── router/              # Vue Router
│   │   └── index.js         # 路由配置+守卫
│   ├── views/               # 页面组件
│   │   ├── Login.vue        # 登录页
│   │   ├── dashboard/       # 仪表盘
│   │   ├── bi/              # 数据分析
│   │   ├── hrm/             # 人力资源
│   │   ├── crm/             # 销售CRM
│   │   ├── purchase/        # 采购管理
│   │   ├── wms/             # 仓储库存
│   │   ├── finance/         # 财务管理
│   │   ├── oa/              # OA办公
│   │   └── system/          # 系统管理
│   ├── utils/
│   │   └── format.js        # 日期/金额/手机格式化
│   ├── styles/
│   │   ├── index.scss       # 全局样式
│   │   ├── variables.scss   # 变量
│   │   └── element-override.scss # Element Plus 暗色覆盖
│   ├── supabase.js          # Supabase 客户端+工具函数
│   ├── main.js              # 应用入口
│   └── App.vue              # 根组件
├── supabase/
│   ├── migrations/
│   │   └── 001_init.sql     # 完整数据库初始化(1058行)
│   └── functions/           # Edge Functions
├── public/                  # 静态资源
├── docs/
│   └── DEPLOYMENT.md        # 本文件
├── index.html
├── vite.config.js
├── package.json
└── .env.example
```
