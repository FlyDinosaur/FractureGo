#!/bin/bash

# 快速修复PM2配置脚本
print_info() {
    echo -e "\033[34m📋 $1\033[0m"
}

print_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[31m❌ $1\033[0m"
}

# 获取当前目录
CURRENT_DIR=$(pwd)

print_info "修复PM2配置文件路径..."
print_info "当前目录: $CURRENT_DIR"

if [ ! -f "ecosystem.config.js" ]; then
    print_error "PM2配置文件不存在"
    exit 1
fi

# 备份原文件
cp ecosystem.config.js ecosystem.config.js.backup
print_info "已备份配置文件"

# 使用更安全的方式替换路径
sed -i.tmp "s|'/path/to/your/server'|'$CURRENT_DIR'|g" ecosystem.config.js

if [ $? -eq 0 ]; then
    rm ecosystem.config.js.tmp 2>/dev/null || true
    print_success "PM2配置路径已更新"
else
    # 如果sed失败，手动创建新配置
    print_info "使用备用方法更新配置..."
    
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'fracturego-server',
    script: 'src/server.js',
    cwd: 'CURRENT_DIR_PLACEHOLDER',
    instances: 'max',
    exec_mode: 'cluster',
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 28974
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 28974
    },
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 4000
  }],

  deploy: {
    production: {
      user: 'ubuntu',
      host: 'your-server-ip',
      ref: 'origin/main',
      repo: 'https://github.com/your-username/fracturego-server.git',
      path: '/home/ubuntu/fracturego-server',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && npm run migrate && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
EOF
    
    # 替换占位符
    sed -i.tmp "s|CURRENT_DIR_PLACEHOLDER|$CURRENT_DIR|g" ecosystem.config.js
    rm ecosystem.config.js.tmp 2>/dev/null || true
    print_success "PM2配置已重新创建"
fi

# 验证配置
print_info "验证配置文件..."
if grep -q "$CURRENT_DIR" ecosystem.config.js; then
    print_success "配置验证成功"
    print_info "配置内容："
    grep "cwd:" ecosystem.config.js
else
    print_error "配置验证失败"
    exit 1
fi

# 重启PM2服务
print_info "重启PM2服务..."
pm2 delete fracturego-server 2>/dev/null || true
pm2 start ecosystem.config.js --env production

print_success "PM2服务重启完成"
print_info "检查服务状态："
pm2 status 