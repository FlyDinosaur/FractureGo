# FractureGo 服务器端代码总结

## 📋 项目概述

FractureGo服务器端是一个基于Node.js + Express + MySQL的康复训练应用后端系统，提供用户管理、训练记录、进度跟踪等核心功能。

### 🎯 主要功能
- **用户管理**：注册、登录、个人信息管理
- **微信集成**：支持微信登录和绑定
- **训练系统**：手部、手臂、腿部三种训练模式
- **进度跟踪**：关卡进度、分数记录、统计分析
- **安全机制**：JWT认证、API密钥验证、请求限流
- **日志系统**：完整的请求日志和错误跟踪

## 🏗️ 技术架构

### 核心技术栈
- **运行环境**：Node.js 18.x
- **Web框架**：Express.js 4.x
- **数据库**：MySQL 8.0
- **进程管理**：PM2
- **认证方式**：JWT + API Key
- **安全中间件**：Helmet、CORS、Rate Limiting

### 项目结构
```
Server/
├── src/
│   ├── server.js              # 服务器主入口
│   ├── config/
│   │   └── database.js        # 数据库配置
│   ├── controllers/
│   │   ├── userController.js  # 用户控制器
│   │   └── trainingController.js # 训练控制器
│   ├── middleware/
│   │   ├── auth.js           # 认证中间件
│   │   └── security.js       # 安全中间件
│   ├── routes/
│   │   └── index.js          # 路由配置
│   └── migrations/
│       └── migrate.js        # 数据库迁移
├── package.json              # 项目依赖
├── ecosystem.config.js       # PM2配置
├── env.example              # 环境变量示例
├── one-click-deploy.sh      # 一键部署脚本
├── deploy.sh               # 标准部署脚本
├── quick-deploy.sh         # 快速部署脚本
└── README.md               # 项目说明
```

## 🔌 API接口文档

### 基础信息
- **服务端口**：28974
- **API前缀**：/api/v1
- **认证方式**：API Key + JWT Token

### 认证相关接口

#### 用户注册
```http
POST /api/v1/auth/register
Content-Type: application/json
X-API-Key: your_api_key

{
  "phoneNumber": "13800138000",
  "password": "password123",
  "nickname": "用户昵称",
  "userType": "patient",
  "birthDate": "1990-01-01",
  "isWeChatUser": false
}
```

#### 用户登录
```http
POST /api/v1/auth/login
Content-Type: application/json
X-API-Key: your_api_key

{
  "phoneNumber": "13800138000",
  "password": "password123"
}
```

#### 微信登录
```http
POST /api/v1/auth/wechat-login
Content-Type: application/json
X-API-Key: your_api_key

{
  "code": "wechat_auth_code",
  "phoneNumber": "13800138000"
}
```

### 用户管理接口

#### 获取用户信息
```http
GET /api/v1/user/profile
Authorization: Bearer jwt_token
X-API-Key: your_api_key
```

#### 更新用户信息
```http
PUT /api/v1/user/profile
Authorization: Bearer jwt_token
X-API-Key: your_api_key
Content-Type: application/json

{
  "nickname": "新昵称",
  "birthDate": "1990-01-01"
}
```

#### 修改密码
```http
PUT /api/v1/user/change-password
Authorization: Bearer jwt_token
X-API-Key: your_api_key
Content-Type: application/json

{
  "oldPassword": "old_password",
  "newPassword": "new_password"
}
```

### 训练相关接口

#### 获取训练进度
```http
GET /api/v1/training/progress?trainingType=hand
Authorization: Bearer jwt_token
X-API-Key: your_api_key
```

#### 记录训练结果
```http
POST /api/v1/training/record
Authorization: Bearer jwt_token
X-API-Key: your_api_key
Content-Type: application/json

{
  "trainingType": "hand",
  "level": 1,
  "score": 85,
  "duration": 120
}
```

#### 获取训练历史
```http
GET /api/v1/training/history?trainingType=hand&page=1&limit=10
Authorization: Bearer jwt_token
X-API-Key: your_api_key
```

#### 获取训练统计
```http
GET /api/v1/training/stats?trainingType=hand&period=7d
Authorization: Bearer jwt_token
X-API-Key: your_api_key
```

#### 更新当前关卡
```http
PUT /api/v1/training/current-level
Authorization: Bearer jwt_token
X-API-Key: your_api_key
Content-Type: application/json

{
  "trainingType": "hand",
  "level": 2
}
```

#### 获取排行榜
```http
GET /api/v1/training/leaderboard?trainingType=hand&period=30d&limit=50
Authorization: Bearer jwt_token
X-API-Key: your_api_key
```

### 系统接口

#### 健康检查
```http
GET /health
```

#### API文档
```http
GET /api/docs
```

## 🗄️ 数据库设计

### 用户表 (users)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 主键 |
| phone_number | VARCHAR(20) | 手机号（唯一） |
| password_hash | VARCHAR(255) | 密码哈希 |
| nickname | VARCHAR(100) | 昵称 |
| user_type | ENUM | 用户类型(patient/doctor/therapist) |
| birth_date | DATE | 出生日期 |
| is_wechat_user | BOOLEAN | 是否微信用户 |
| wechat_open_id | VARCHAR(100) | 微信OpenID |
| wechat_union_id | VARCHAR(100) | 微信UnionID |
| status | ENUM | 用户状态 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |
| last_login_at | TIMESTAMP | 最后登录时间 |

### 训练记录表 (training_records)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 主键 |
| user_id | INT | 用户ID |
| training_type | ENUM | 训练类型(hand/arm/leg) |
| level | INT | 训练关卡 |
| score | INT | 训练分数 |
| duration | INT | 训练时长(秒) |
| completed_at | TIMESTAMP | 完成时间 |
| data | JSON | 训练详细数据 |

### 用户进度表 (user_progress)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 主键 |
| user_id | INT | 用户ID |
| training_type | ENUM | 训练类型 |
| current_level | INT | 当前关卡 |
| max_level_reached | INT | 最高关卡 |
| total_training_time | INT | 总训练时长 |
| total_sessions | INT | 总训练次数 |
| best_score | INT | 最佳分数 |
| updated_at | TIMESTAMP | 更新时间 |

### API密钥表 (api_keys)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT | 主键 |
| key_name | VARCHAR(100) | 密钥名称 |
| api_key | VARCHAR(255) | API密钥 |
| permissions | JSON | 权限列表 |
| is_active | BOOLEAN | 是否激活 |
| expires_at | TIMESTAMP | 过期时间 |
| created_at | TIMESTAMP | 创建时间 |

## 🚀 部署指南

### 环境要求
- **操作系统**：Ubuntu 18.04+ / CentOS 7+ / Debian 9+
- **Node.js**：18.x 或更高版本
- **MySQL**：8.0 或更高版本
- **内存**：至少 2GB
- **磁盘空间**：至少 10GB

### 一键部署（推荐）

1. **下载部署脚本**
```bash
wget https://raw.githubusercontent.com/FlyDinosaur/FractureGo-Server/main/one-click-deploy.sh
chmod +x one-click-deploy.sh
```

2. **运行部署脚本**
```bash
# 普通用户运行
./one-click-deploy.sh

# 或者root用户运行
sudo ./one-click-deploy.sh
```

3. **部署过程说明**
   - 自动检测操作系统类型
   - 安装Node.js、PM2、MySQL等依赖
   - 配置数据库和用户权限
   - 克隆代码并安装依赖
   - 自动生成环境变量和密钥
   - 运行数据库迁移
   - 启动PM2服务
   - 配置防火墙规则

### 手动部署

1. **克隆代码**
```bash
git clone https://github.com/FlyDinosaur/FractureGo-Server.git
cd FractureGo-Server
```

2. **安装依赖**
```bash
npm install --production
```

3. **配置环境变量**
```bash
cp env.example .env
# 编辑.env文件，填入实际配置
```

4. **运行数据库迁移**
```bash
npm run migrate
```

5. **启动服务**
```bash
npm run deploy
```

### 快速部署（已配置SSH）

如果已经配置好GitHub SSH密钥：

```bash
wget https://raw.githubusercontent.com/FlyDinosaur/FractureGo-Server/main/quick-deploy.sh
chmod +x quick-deploy.sh
./quick-deploy.sh
```

## 🔧 配置说明

### 环境变量配置 (.env)

```bash
# 服务器配置
PORT=28974
NODE_ENV=production

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=fracturego_db
DB_USER=fracturego_user
DB_PASSWORD=your_secure_password

# JWT配置
JWT_SECRET=your_jwt_secret_key_at_least_32_characters_long
JWT_EXPIRES_IN=7d

# 安全配置
API_KEY=your_api_key_for_client_authentication
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# 微信配置
WECHAT_APP_ID=your_wechat_app_id
WECHAT_APP_SECRET=your_wechat_app_secret

# 文件上传配置
UPLOAD_MAX_SIZE=10485760
UPLOAD_PATH=uploads/
```

### PM2 配置 (ecosystem.config.js)

```javascript
module.exports = {
  apps: [{
    name: 'fracturego-server',
    script: 'src/server.js',
    instances: 'max',
    exec_mode: 'cluster',
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 28974
    }
  }]
};
```

## 🔐 安全机制

### 认证系统
- **双重认证**：API Key + JWT Token
- **密码加密**：使用bcryptjs进行加密
- **Token管理**：支持Token刷新和过期管理

### 安全中间件
- **Helmet**：设置安全HTTP头
- **CORS**：跨域资源共享控制
- **Rate Limiting**：请求频率限制
- **Input Validation**：输入数据验证

### 日志系统
- **请求日志**：记录所有API请求
- **错误日志**：记录系统错误和异常
- **性能监控**：响应时间和资源使用

## 📊 监控和维护

### PM2 常用命令
```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs fracturego-server

# 重启服务
pm2 restart fracturego-server

# 停止服务
pm2 stop fracturego-server

# 查看监控信息
pm2 monit
```

### 数据库维护
```bash
# 备份数据库
mysqldump -u fracturego_user -p fracturego_db > backup.sql

# 恢复数据库
mysql -u fracturego_user -p fracturego_db < backup.sql

# 查看连接数
SHOW PROCESSLIST;

# 查看表大小
SELECT table_name, table_rows, data_length, index_length 
FROM information_schema.tables 
WHERE table_schema = 'fracturego_db';
```

### 性能优化
- **数据库索引优化**：为常用查询添加合适索引
- **连接池配置**：优化数据库连接池大小
- **缓存策略**：使用Redis缓存热点数据
- **负载均衡**：使用PM2集群模式

## 🐛 故障排除

### 常见问题

1. **服务无法启动**
   - 检查端口是否被占用：`netstat -tulpn | grep 28974`
   - 检查数据库连接：`mysql -u fracturego_user -p`
   - 查看PM2日志：`pm2 logs fracturego-server`

2. **数据库连接失败**
   - 检查MySQL服务：`systemctl status mysql`
   - 验证数据库配置：检查.env文件中的数据库配置
   - 测试连接：`mysql -h localhost -u fracturego_user -p`

3. **API请求失败**
   - 检查API密钥是否正确
   - 验证JWT Token是否过期
   - 查看请求日志确认错误原因

### 日志文件位置
- **PM2日志**：`~/.pm2/logs/`
- **应用日志**：`./logs/fracturego.log`
- **错误日志**：`./logs/err.log`
- **访问日志**：`./logs/out.log`

## 📈 扩展功能

### 计划中的功能
- **Redis缓存**：提高API响应速度
- **文件上传**：支持训练视频和图片上传
- **实时通信**：WebSocket支持实时数据传输
- **数据分析**：训练数据的深度分析和可视化
- **推送通知**：训练提醒和进度通知

### 集成建议
- **监控系统**：集成Prometheus + Grafana
- **日志分析**：使用ELK Stack分析日志
- **容器化**：使用Docker进行容器化部署
- **CI/CD**：配置GitHub Actions自动部署

## 📝 API响应格式

### 成功响应
```json
{
  "success": true,
  "message": "操作成功",
  "data": {
    // 具体数据
  }
}
```

### 错误响应
```json
{
  "success": false,
  "message": "错误描述",
  "errors": [
    // 详细错误信息
  ]
}
```

## 🔄 版本更新

### 更新流程
1. **备份当前版本**
2. **拉取最新代码**：`git pull origin main`
3. **安装新依赖**：`npm install --production`
4. **运行数据库迁移**：`npm run migrate`
5. **重启服务**：`pm2 restart fracturego-server`

### 回滚操作
1. **停止当前服务**：`pm2 stop fracturego-server`
2. **恢复代码版本**：`git checkout previous_version`
3. **恢复数据库**：从备份恢复
4. **重启服务**：`pm2 start fracturego-server`

---

## 📞 技术支持

如果在部署或使用过程中遇到问题，可以：

1. **查看文档**：仔细阅读本文档和README.md
2. **检查日志**：查看详细的错误日志信息
3. **Issue反馈**：在GitHub仓库创建Issue
4. **联系开发者**：通过项目联系方式获取支持

**项目仓库**：https://github.com/FlyDinosaur/FractureGo-Server

---

*文档最后更新：2024年12月* 