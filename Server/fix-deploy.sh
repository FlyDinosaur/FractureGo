#!/bin/bash

# FractureGo部署修复脚本
# 解决当前目录冲突问题

set -e

echo "🔧 FractureGo部署修复脚本"
echo "=========================="

# 颜色输出函数
print_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[31m❌ $1\033[0m"
}

print_info() {
    echo -e "\033[34m📋 $1\033[0m"
}

print_warning() {
    echo -e "\033[33m⚠️ $1\033[0m"
}

# 配置变量
SERVER_DIR="/opt/fracturego-server"
DB_NAME="fracturego_db"
DB_USER="fracturego_user"
SERVICE_NAME="fracturego-server"
PORT=28974

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    print_error "请使用root用户运行此修复脚本"
    exit 1
fi

# 修复部署目录
fix_deployment_directory() {
    print_info "修复部署目录..."
    
    # 确保目录存在
    mkdir -p $SERVER_DIR
    cd $SERVER_DIR
    
    # 修复Git安全目录问题
    git config --global --add safe.directory $SERVER_DIR
    
    # 检查目录状态
    if [ -d ".git" ]; then
        print_info "发现现有Git仓库，更新代码..."
        git pull origin main
    else
        print_info "清理目录并重新克隆代码..."
        
        # 清理目录
        rm -rf *
        rm -rf .[^.]*
        
        # 克隆代码
        print_info "从GitHub克隆最新代码..."
        if git clone git@github.com:FlyDinosaur/FractureGo-Server.git .; then
            print_success "SSH克隆成功"
        elif git clone https://github.com/FlyDinosaur/FractureGo-Server.git .; then
            print_success "HTTPS克隆成功"
        else
            print_error "代码克隆失败"
            exit 1
        fi
    fi
    
    print_success "代码获取完成"
}

# 安装依赖
install_dependencies() {
    print_info "安装Node.js依赖..."
    
    cd $SERVER_DIR
    npm install --production
    
    print_success "依赖安装完成"
}

# 配置环境文件
setup_environment() {
    print_info "配置环境文件..."
    
    cd $SERVER_DIR
    
    if [ ! -f ".env" ]; then
        cp env.example .env
        
        # 生成密钥
        JWT_SECRET=$(openssl rand -base64 64)
        API_KEY=$(openssl rand -hex 32)
        
        # 从数据库配置获取密码
        if [ -f "/tmp/fracturego_db_config" ]; then
            source /tmp/fracturego_db_config
            print_info "使用已保存的数据库配置"
        else
            print_warning "生成符合MySQL密码策略的新密码"
            # 生成强密码：包含大写、小写、数字、特殊字符
            local password_part=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)
            DB_PASSWORD="Fracture${password_part}2024!"
        fi
        
        # 直接创建.env文件（避免sed特殊字符问题）
        cat > .env << EOF
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# 服务器配置
PORT=$PORT
NODE_ENV=production

# 安全配置
JWT_SECRET=$JWT_SECRET
API_KEY=$API_KEY

# 日志配置
LOG_LEVEL=info
LOG_FILE=logs/app.log

# 上传配置
UPLOAD_DIR=uploads
MAX_FILE_SIZE=10485760
EOF
        
        print_success "环境配置完成"
        print_info "API密钥: $API_KEY"
    else
        print_info "环境文件已存在"
    fi
}

# 设置权限
set_permissions() {
    print_info "设置文件权限..."
    
    chown -R fracturego:fracturego $SERVER_DIR
    chmod +x $SERVER_DIR/deploy.sh
    
    print_success "权限设置完成"
}

# 运行数据库迁移
run_migration() {
    print_info "运行数据库迁移..."
    
    cd $SERVER_DIR
    
    # 检查package.json中是否有migrate脚本
    if npm run | grep -q "migrate"; then
        npm run migrate
        print_success "数据库迁移完成"
    else
        print_warning "未找到数据库迁移脚本，跳过此步骤"
    fi
}

# 启动服务
start_services() {
    print_info "启动服务..."
    
    cd $SERVER_DIR
    
    # 更新PM2配置文件中的路径
    print_info "更新PM2配置..."
    if [ -f "ecosystem.config.js" ]; then
        sed -i "s|'/path/to/your/server'|'$SERVER_DIR'|g" ecosystem.config.js
        print_success "PM2配置已更新"
    else
        print_warning "PM2配置文件不存在"
    fi
    
    # 停止现有进程
    su - fracturego -c "cd $SERVER_DIR && pm2 delete $SERVICE_NAME" 2>/dev/null || true
    
    # 启动新进程
    su - fracturego -c "cd $SERVER_DIR && pm2 start ecosystem.config.js --env production"
    
    # 保存配置
    su - fracturego -c "pm2 save"
    
    print_success "服务启动完成"
}

# 验证部署
verify_deployment() {
    print_info "验证部署..."
    
    sleep 3
    
    # 检查服务状态
    if su - fracturego -c "pm2 describe $SERVICE_NAME" > /dev/null 2>&1; then
        print_success "服务运行正常"
    else
        print_warning "服务状态检查失败"
    fi
    
    # 检查端口
    if netstat -tlnp | grep ":$PORT " > /dev/null; then
        print_success "端口 $PORT 正在监听"
    else
        print_warning "端口 $PORT 未检测到监听"
    fi
    
    print_info "部署验证完成"
}

# 显示部署信息
show_info() {
    print_success "FractureGo服务器部署修复完成！"
    echo ""
    echo "🌐 服务信息："
    echo "   - 服务地址: http://localhost:$PORT"
    echo "   - 健康检查: curl http://localhost:$PORT/health"
    echo "   - 项目目录: $SERVER_DIR"
    echo ""
    echo "🔧 管理命令："
    echo "   - 查看状态: su - fracturego -c 'pm2 status'"
    echo "   - 查看日志: su - fracturego -c 'pm2 logs'"
    echo "   - 重启服务: su - fracturego -c 'pm2 restart $SERVICE_NAME'"
    echo ""
    
    # 显示API密钥
    if [ -f "$SERVER_DIR/.env" ]; then
        API_KEY=$(grep "^API_KEY=" "$SERVER_DIR/.env" | cut -d '=' -f2)
        echo "🔑 API密钥: $API_KEY"
        echo "   客户端请求头: X-API-Key: $API_KEY"
    fi
}

# 主函数
main() {
    fix_deployment_directory
    install_dependencies
    setup_environment
    set_permissions
    run_migration
    start_services
    verify_deployment
    show_info
}

# 运行主函数
main "$@" 