# FractureGo 服务端

## 项目简介

FractureGo服务端是一个基于Node.js + Express + MySQL的康复训练管理系统API服务，为FractureGo iOS应用提供数据存储和用户管理功能。

## 功能特性

- 🔐 **用户认证系统** - 支持手机号注册/登录、微信登录
- 📊 **训练数据管理** - 记录和统计用户的康复训练数据
- 🏆 **进度跟踪** - 用户训练进度和成就记录
- 🛡️ **安全防护** - API密钥验证、JWT Token、请求限制
- 📈 **性能监控** - 请求日志、错误追踪、性能指标
- 🚀 **自动部署** - 支持一键部署到Linux服务器

## 技术栈

- **后端框架**: Node.js + Express.js
- **数据库**: MySQL 8.0+
- **认证**: JWT + API Key
- **安全**: Helmet, CORS, Rate Limiting
- **进程管理**: PM2
- **反向代理**: Nginx (可选)

## 快速开始

### 环境要求

- Node.js >= 16.0.0
- MySQL >= 8.0
- PM2 (生产环境)
- Linux服务器 (Ubuntu 20.04+ 推荐)

### 本地开发

1. **克隆项目**
```bash
git clone https://github.com/your-username/fracturego-server.git
cd fracturego-server
```

2. **安装依赖**
```bash
npm install
```

3. **配置环境变量**
```bash
cp env.example .env
# 编辑.env文件，填入正确的配置信息
```

4. **创建数据库**
```bash
mysql -u root -p
CREATE DATABASE fracturego_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

5. **运行数据库迁移**
```bash
npm run migrate
```

6. **启动开发服务器**
```bash
npm run dev
```

服务器将在 http://localhost:28974 启动

### 生产环境部署

#### 方法一：自动部署脚本（推荐）

1. **上传部署脚本到服务器**
```bash
scp deploy.sh user@your-server:/home/user/
```

2. **运行部署脚本**
```bash
chmod +x deploy.sh
./deploy.sh
```

部署脚本将自动完成以下操作：
- 安装系统依赖 (Node.js, PM2, MySQL)
- 配置数据库
- 克隆代码并安装依赖
- 生成安全密钥
- 运行数据库迁移
- 配置防火墙
- 启动服务
- 配置Nginx反向代理（可选）

#### 方法二：手动部署

1. **在服务器上克隆项目**
```bash
git clone https://github.com/your-username/fracturego-server.git
cd fracturego-server
```

2. **安装依赖**
```bash
npm install --production
```

3. **配置环境变量**
```bash
cp env.example .env
# 编辑.env文件配置生产环境参数
```

4. **运行数据库迁移**
```bash
npm run migrate
```

5. **启动服务**
```bash
npm run deploy
```

## 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 | 必需 |
|--------|------|--------|------|
| `PORT` | 服务器端口 | 28974 | ✅ |
| `NODE_ENV` | 运行环境 | development | ✅ |
| `DB_HOST` | 数据库主机 | localhost | ✅ |
| `DB_PORT` | 数据库端口 | 3306 | ✅ |
| `DB_NAME` | 数据库名称 | fracturego_db | ✅ |
| `DB_USER` | 数据库用户 | fracturego_user | ✅ |
| `DB_PASSWORD` | 数据库密码 | - | ✅ |
| `JWT_SECRET` | JWT密钥 | - | ✅ |
| `API_KEY` | API密钥 | - | ✅ |
| `RATE_LIMIT_WINDOW_MS` | 限流窗口时间 | 900000 | ❌ |
| `RATE_LIMIT_MAX_REQUESTS` | 最大请求数 | 100 | ❌ |

### 数据库配置

数据库连接配置在 `src/config/database.js` 中，支持连接池和自动重连。

### API密钥配置

API密钥存储在数据库的 `api_keys` 表中，客户端需要在请求头中添加：
```
X-API-Key: your_api_key_here
```

## API文档

### 基础信息

- **Base URL**: `http://your-server:28974/api/v1`
- **认证方式**: API Key + JWT Token
- **请求格式**: JSON
- **响应格式**: JSON

### 端点列表

#### 健康检查
```
GET /health
```

#### 用户认证
```
POST /api/v1/auth/register    # 用户注册
POST /api/v1/auth/login       # 用户登录
POST /api/v1/auth/wechat-login # 微信登录
```

#### 用户管理
```
GET /api/v1/user/profile      # 获取用户信息
PUT /api/v1/user/profile      # 更新用户信息
PUT /api/v1/user/change-password # 修改密码
```

#### 训练管理
```
GET /api/v1/training/progress    # 获取训练进度
POST /api/v1/training/record     # 记录训练成绩
GET /api/v1/training/history     # 获取训练历史
GET /api/v1/training/stats       # 获取训练统计
PUT /api/v1/training/current-level # 更新当前关卡
GET /api/v1/training/leaderboard # 获取排行榜
```

### 请求示例

#### 用户登录
```bash
curl -X POST http://localhost:28974/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your_api_key" \
  -d '{
    "phoneNumber": "13812345678",
    "password": "password123"
  }'
```

#### 记录训练成绩
```bash
curl -X POST http://localhost:28974/api/v1/training/record \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your_api_key" \
  -H "Authorization: Bearer jwt_token" \
  -d '{
    "trainingType": "hand",
    "level": 1,
    "score": 85,
    "duration": 120
  }'
```

## 运维管理

### PM2 命令

```bash
# 查看服务状态
pm2 list

# 查看日志
pm2 logs fracturego-server

# 重启服务
pm2 restart fracturego-server

# 停止服务
pm2 stop fracturego-server

# 删除服务
pm2 delete fracturego-server

# 监控服务
pm2 monit
```

### 日志管理

日志文件位置：
- 应用日志: `logs/combined.log`
- 错误日志: `logs/err.log`
- 输出日志: `logs/out.log`

### 数据库管理

```bash
# 连接数据库
mysql -u fracturego_user -p fracturego_db

# 备份数据库
mysqldump -u fracturego_user -p fracturego_db > backup.sql

# 恢复数据库
mysql -u fracturego_user -p fracturego_db < backup.sql
```

## 监控和安全

### 安全特性

- ✅ API密钥验证
- ✅ JWT Token认证  
- ✅ 请求速率限制
- ✅ CORS保护
- ✅ Helmet安全头
- ✅ 输入验证
- ✅ SQL注入防护
- ✅ XSS防护

### 监控指标

- 请求响应时间
- 错误率统计
- API调用频率
- 数据库连接状态
- 内存和CPU使用率

## 故障排除

### 常见问题

1. **服务启动失败**
   - 检查环境变量配置
   - 确认数据库连接
   - 查看PM2日志

2. **数据库连接错误**
   - 验证数据库凭据
   - 检查数据库服务状态
   - 确认网络连接

3. **API请求失败**
   - 验证API密钥
   - 检查JWT Token有效性
   - 确认请求格式

### 获取帮助

- 查看日志: `pm2 logs fracturego-server`
- 检查服务状态: `pm2 list`
- 测试API健康: `curl http://localhost:28974/health`

## 开发指南

### 项目结构

```
Server/
├── src/
│   ├── config/          # 配置文件
│   ├── controllers/     # 控制器
│   ├── middleware/      # 中间件
│   ├── routes/         # 路由定义
│   ├── migrations/     # 数据库迁移
│   └── server.js       # 主服务器文件
├── logs/              # 日志目录
├── package.json       # 项目配置
├── ecosystem.config.js # PM2配置
└── deploy.sh         # 部署脚本
```

### 开发规范

- 使用 ES6+ 语法
- 遵循 RESTful API 设计
- 所有输入都需要验证
- 错误处理要完整
- 代码注释要清晰

## 许可证

MIT License

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 用户认证系统
- 训练数据管理
- 安全防护机制
- 自动部署脚本

---

**注意**: 在生产环境中，请确保更改默认的API密钥和JWT密钥，并定期更新系统安全补丁。 