# 个人工作台

一个纯静态的个人工作管理应用，前端集中在 `index.html`，后端使用 Supabase 提供认证、数据库和 Row Level Security。项目可以直接部署到 GitHub Pages，不需要 Node、打包工具或服务器。

## 在线部署

GitHub Pages 地址：

```text
https://shimu-huang666.github.io/work-dashboard/
```

GitHub 仓库：

```text
https://github.com/shimu-huang666/work-dashboard
```

## 功能

- 邮箱注册、登录、退出、密码重置
- 仪表盘：任务概览、今日计划、最近笔记、目标进度
- 任务看板：待办、进行中、已完成
- 工作日记：日历选择、心情标记、AI 辅助处理
- 未来计划：按状态筛选、新建、编辑、删除
- 目标管理：目标进度、单位、截止日期、里程碑
- 笔记系统：标签、置顶、Markdown 预览、自动保存、AI 续写/润色/总结/翻译
- AI 配置：Claude、Deepseek、小米 MIMO 按量付费、小米 MIMO Token Plan

## 技术栈

- HTML / CSS / JavaScript
- Supabase JavaScript SDK v2
- Supabase Auth
- Supabase Postgres
- GitHub Pages

## 项目结构

```text
.
├── index.html             # 单页前端应用
├── supabase-setup.sql     # 基础数据库初始化脚本
├── auth-migration.sql     # 登录用户隔离迁移脚本
├── feature-migration.sql  # 目标、里程碑、任务标签等增强功能迁移
├── work_profiles.sql      # 用户配置扩展表
└── README.md              # 项目说明
```

## 本地运行

项目没有 npm 依赖，可以直接使用静态服务器：

```powershell
python -m http.server 5500
```

然后访问：

```text
http://localhost:5500/index.html
```

也可以直接双击打开 `index.html`，但登录跳转、密码重置和浏览器安全策略在本地静态服务器下更稳定。

## GitHub Pages 配置

仓库是普通静态网站，GitHub Pages 使用分支根目录发布即可：

1. 打开 GitHub 仓库。
2. 进入 `Settings`。
3. 左侧选择 `Pages`。
4. `Source` 选择 `Deploy from a branch`。
5. `Branch` 选择 `master`。
6. 文件夹选择 `/(root)`。
7. 保存后等待 Pages 自动部署。

只要 `index.html` 位于 `master` 分支根目录，页面就会发布到：

```text
https://shimu-huang666.github.io/work-dashboard/
```

## Supabase 后端配置

### 1. 创建项目

进入 Supabase 控制台创建项目：

```text
https://supabase.com/dashboard
```

创建后在 `Project Settings -> API` 中复制：

- Project URL
- Publishable key / anon key

然后在 `index.html` 中替换：

```js
const SUPABASE_URL = '你的 Supabase Project URL';
const SUPABASE_KEY = '你的 Supabase publishable key';
```

注意：publishable key 可以出现在前端页面中，真正的数据安全依赖 RLS 策略。不要把 `service_role` key 写入前端。

### 2. 执行数据库脚本

进入 Supabase 控制台：

```text
SQL Editor -> New query
```

按顺序执行以下脚本：

1. `supabase-setup.sql`
2. `auth-migration.sql`
3. `feature-migration.sql`
4. `work_profiles.sql`

脚本作用：

| 脚本 | 作用 |
| --- | --- |
| `supabase-setup.sql` | 创建 `tasks`、`daily_logs`、`plans`、`notes`，添加更新时间触发器、索引和基础 RLS |
| `auth-migration.sql` | 为主表添加 `user_id`，把 RLS 改成用户只能访问自己的数据 |
| `feature-migration.sql` | 添加任务标签、目标表 `goals`、里程碑表 `milestones` |
| `work_profiles.sql` | 创建用户配置表 `work_profiles`，用于后续保存用户偏好 |

### 3. 数据表说明

| 表名 | 用途 |
| --- | --- |
| `tasks` | 看板任务，包含标题、描述、状态、优先级、截止日期、标签、用户归属 |
| `daily_logs` | 每日记录，包含日期、内容、心情、用户归属 |
| `plans` | 未来计划，包含目标日期、状态、用户归属 |
| `notes` | 笔记，包含标题、内容、标签、置顶状态、用户归属 |
| `goals` | 目标，包含目标值、当前值、单位、截止日期、状态、用户归属 |
| `milestones` | 目标里程碑，通过 `goal_id` 关联 `goals` |
| `work_profiles` | 用户配置扩展表 |

### 4. 启用认证

进入：

```text
Authentication -> Providers -> Email
```

建议配置：

- 启用 Email 登录。
- 根据需要启用 Confirm email。
- 如果公开部署，建议开启防滥用配置，例如验证码、自定义 SMTP、合理的邮件频率限制。

### 5. 配置站点 URL 和跳转地址

进入：

```text
Authentication -> URL Configuration
```

设置：

```text
Site URL:
https://shimu-huang666.github.io/work-dashboard/

Redirect URLs:
http://localhost:5500/**
https://shimu-huang666.github.io/work-dashboard/**
```

如果你的本地端口不是 `5500`，把对应的 localhost 地址也加入 Redirect URLs。

### 6. 检查 RLS

进入：

```text
Authentication -> Policies
```

确认这些表已经启用 RLS，并且策略按用户隔离：

- `tasks`
- `daily_logs`
- `plans`
- `notes`
- `goals`
- `milestones`
- `work_profiles`

核心原则：

```sql
auth.uid() = user_id
```

前端所有新增任务、日记、计划、笔记、目标时都会写入当前登录用户的 `user_id`。如果历史数据没有 `user_id`，执行用户级 RLS 后这些数据会被隐藏，需要手动补齐归属用户。

## Supabase 免费项目 7 天不访问会怎样

Supabase 官方生产检查清单说明：Free Plan 项目如果在 7 天周期内活跃度较低，Supabase 可能会暂停项目以节省服务器资源。暂停后：

- 前端 GitHub Pages 仍然能打开。
- 登录、读取、保存数据等依赖 Supabase 的功能会失败或不可用。
- 可以进入 Supabase Dashboard 手动恢复项目。
- 升级到 Pro 后，官方说明项目不会因为不活跃而被暂停。

另外，Supabase 官方升级文档说明：项目暂停后，通常有 90 天窗口可以在 Studio 中一键恢复；超过这个窗口后，一键恢复可能不可用，需要下载备份并迁移到新项目。

相关官方文档：

- Supabase Production Checklist: https://supabase.com/docs/guides/deployment/going-into-prod
- Supabase Billing: https://supabase.com/docs/guides/platform/billing-on-supabase
- Supabase Pause and Restore / 90-day restore window: https://supabase.com/docs/guides/platform/upgrading

建议：

- 免费项目至少定期打开一次应用或 Supabase Dashboard。
- 重要数据定期导出。
- 如果这是长期使用的个人工作台，考虑升级到 Pro，避免因低活跃被暂停。

## AI 配置

进入应用的 `设置` 页面，可以选择 AI 服务提供商，并填写 API Key、端点和模型。

### Claude

```text
Endpoint:
https://api.anthropic.com/v1/messages

默认模型:
claude-sonnet-4-20250514
```

### Deepseek

```text
Endpoint:
https://api.deepseek.com/v1/chat/completions

默认模型:
deepseek-chat
```

### 小米 MIMO，按量付费

```text
Endpoint:
https://api.xiaomimimo.com/v1/chat/completions

默认模型:
mimo-v2-flash

可选模型:
mimo-v2-flash
mimo-v2-pro
mimo-v2-omni
```

### 小米 MIMO Token Plan

```text
Endpoint:
https://token-plan-sgp.xiaomimimo.com/anthropic/v1/messages

默认模型:
mimo-v2.5-pro

可选模型:
mimo-v2.5-pro
mimo-v2.5
mimo-v2-pro
mimo-v2-flash
mimo-v2-omni
```

注意：当前项目是纯前端应用，AI API Key 会保存在浏览器 localStorage。个人使用可以接受；如果要公开给多人使用，建议增加自己的后端代理，不要让用户共享同一组 API Key。

## 常见问题

### 页面能打开，但登录或数据加载失败

检查：

- `index.html` 中的 `SUPABASE_URL` 和 `SUPABASE_KEY` 是否正确。
- Supabase 项目是否被暂停。
- Authentication 的 Site URL 和 Redirect URLs 是否包含当前访问地址。
- 相关 SQL 脚本是否全部执行。
- RLS 策略是否正确。

### 保存日记失败

当前 `daily_logs` 的基础脚本里 `date` 是全局唯一：

```sql
date DATE NOT NULL UNIQUE
```

如果多个用户都要在同一天写日记，建议改成 `(user_id, date)` 联合唯一约束。

### 旧数据看不到

执行 `auth-migration.sql` 后，RLS 会要求数据的 `user_id` 等于当前登录用户。如果旧数据的 `user_id` 为空，它不会显示。需要在数据库里手动把旧数据关联到对应用户。

## 部署提醒

- GitHub Pages 只负责托管静态文件。
- Supabase 才是认证和数据库后端。
- 前端可以公开 publishable key，但不能公开 service role key。
- 所有涉及用户数据的表都必须启用 RLS。
- 如果更换域名，记得同步更新 Supabase 的 Site URL 和 Redirect URLs。

