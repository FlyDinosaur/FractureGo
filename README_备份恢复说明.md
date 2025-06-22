# FractureGo 服务器备份恢复说明

## 备份信息
- **备份时间**: 2025年6月23日 02:35:47
- **服务器IP**: 117.72.161.6
- **备份大小**: 21MB
- **备份内容**: 
  - 完整项目代码 (FractureGo-Server)
  - 数据库完整备份 (fracturego_db)
  - PM2 进程管理器配置
  - Nginx 配置文件
  - 系统运行状态信息

## 文件说明
- `fracturego_complete_backup.tar.gz` - 完整服务器备份文件
- `restore.sh` - 一键恢复脚本
- `README_备份恢复说明.md` - 此说明文件

## 快速恢复方法

### 1. 解压备份文件
```bash
tar -xzf fracturego_backup_20250623_023547.tar.gz
cd server_backup_20250623_023547
```

### 2. 一键恢复（推荐）
```bash
./restore.sh
```

### 3. 手动恢复（高级用户）
如果需要手动恢复，请按以下步骤：

#### 3.1 上传备份文件
```bash
sshpass -p "WYX11037414qq" scp fracturego_complete_backup.tar.gz root@117.72.161.6:/tmp/
```

#### 3.2 连接服务器并解压
```bash
sshpass -p "WYX11037414qq" ssh root@117.72.161.6
cd /tmp
tar -xzf fracturego_complete_backup.tar.gz
```

#### 3.3 恢复项目代码
```bash
# 停止现有服务
pm2 stop all

# 备份现有代码
mv /root/FractureGo-Server /root/FractureGo-Server.backup.$(date +%Y%m%d_%H%M%S)

# 恢复项目代码
cp -r /tmp/fracturego_backup/project_code/FractureGo-Server /root/
```

#### 3.4 恢复数据库
```bash
mysql -h 117.72.161.6 -u fracturego_user -pWYX11037414qq fracturego_db < /tmp/fracturego_backup/database_backup.sql
```

#### 3.5 恢复PM2配置并启动服务
```bash
cp -r /tmp/fracturego_backup/pm2_config/.pm2 ~/
cd /root/FractureGo-Server
npm install
pm2 start ecosystem.config.js
pm2 save
```

## 备份内容详情

### 项目代码
- 完整的 FractureGo-Server 项目目录
- 包含所有源代码、配置文件、依赖信息

### 数据库备份
- 数据库名: fracturego_db
- 备份大小: 260KB
- 包含所有表结构和数据

### 系统配置
- PM2 进程管理器完整配置
- Nginx 反向代理配置
- 系统进程和端口信息
- 定时任务配置

## 注意事项

1. **网络连接**: 确保本地计算机能够访问目标服务器 (117.72.161.6)
2. **权限要求**: 需要 root 权限进行系统级恢复
3. **服务停机**: 恢复过程中服务会短暂停止
4. **备份现有数据**: 恢复前会自动备份现有代码，数据库请手动备份
5. **依赖安装**: 恢复后会自动安装 npm 依赖

## 验证恢复

恢复完成后，请检查以下项目：

1. **服务状态**
   ```bash
   pm2 status
   ```

2. **端口监听**
   ```bash
   netstat -tulpn | grep :3000
   ```

3. **数据库连接**
   ```bash
   mysql -h 117.72.161.6 -u fracturego_user -pWYX11037414qq fracturego_db -e "SHOW TABLES;"
   ```

4. **Web服务访问**
   ```bash
   curl http://117.72.161.6:3000/api/health
   ```

## 联系支持

如果在恢复过程中遇到问题，请检查：
- 网络连接是否正常
- 服务器账号密码是否正确
- 磁盘空间是否充足

---
**备份创建时间**: 2025年6月23日 02:35:47  
**脚本版本**: 1.0  
**备份类型**: 完整备份 