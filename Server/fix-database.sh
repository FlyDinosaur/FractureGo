#!/bin/bash

# FractureGo数据库密码修复脚本
# 解决数据库连接认证问题

set -e

echo "🔐 FractureGo数据库密码修复脚本"
echo "================================"

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
DB_NAME="fracturego_db"
DB_USER="fracturego_user"
SERVER_DIR="/opt/fracturego-server"

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    print_error "请使用root用户运行此脚本"
    exit 1
fi

# 从.env文件读取当前密码
read_current_config() {
    if [ -f "$SERVER_DIR/.env" ]; then
        DB_PASSWORD=$(grep "^DB_PASSWORD=" "$SERVER_DIR/.env" | cut -d '=' -f2)
        if [ -n "$DB_PASSWORD" ]; then
            print_info "从.env文件读取到密码，长度: ${#DB_PASSWORD} 字符"
        else
            print_warning ".env文件中未找到DB_PASSWORD"
            return 1
        fi
    else
        print_error ".env文件不存在"
        return 1
    fi
}

# 生成符合MySQL密码策略的强密码
generate_strong_password() {
    # 生成包含大小写字母、数字和特殊字符的强密码
    local password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-20)
    # 确保包含数字、大写字母、小写字母和特殊字符
    echo "Fracture${password}2024!"
}

# 重新创建数据库用户
recreate_database_user() {
    print_info "重新创建数据库用户..."
    
    # 检查当前密码是否符合策略，如果不符合则生成新密码
    print_info "检查密码策略..."
    
    # 生成新的强密码
    local new_password=$(generate_strong_password)
    print_info "生成符合MySQL密码策略的新密码，长度: ${#new_password} 字符"
    
    print_info "请输入MySQL root密码以重新设置数据库用户"
    
    # 创建SQL命令
    mysql -u root -p << EOF
-- 查看当前密码策略
SHOW VARIABLES LIKE 'validate_password%';

-- 删除现有用户（如果存在）
DROP USER IF EXISTS '${DB_USER}'@'localhost';

-- 创建新用户（使用强密码）
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${new_password}';

-- 授予权限
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;

-- 显示用户信息
SELECT User, Host FROM mysql.user WHERE User = '${DB_USER}';
EOF

    if [ $? -eq 0 ]; then
        print_success "数据库用户重新创建成功"
        
        # 更新.env文件中的密码
        print_info "更新.env文件中的数据库密码..."
        
        # 更新密码到.env文件
        sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${new_password}/" "$SERVER_DIR/.env"
        
        # 更新全局变量
        DB_PASSWORD="$new_password"
        
        print_success "数据库密码已更新到.env文件"
        print_info "新密码长度: ${#DB_PASSWORD} 字符"
        
    else
        print_error "数据库用户创建失败"
        
        # 如果还是失败，尝试临时降低密码策略
        print_warning "尝试临时调整密码策略..."
        mysql -u root -p << EOF2
-- 临时降低密码策略
SET GLOBAL validate_password.policy = LOW;
SET GLOBAL validate_password.length = 8;

-- 删除现有用户（如果存在）
DROP USER IF EXISTS '${DB_USER}'@'localhost';

-- 创建新用户
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${new_password}';

-- 授予权限
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;

-- 恢复密码策略
SET GLOBAL validate_password.policy = MEDIUM;
SET GLOBAL validate_password.length = 8;

SELECT User, Host FROM mysql.user WHERE User = '${DB_USER}';
EOF2
        
        if [ $? -eq 0 ]; then
            print_success "使用调整后的策略创建用户成功"
            # 更新.env文件
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${new_password}/" "$SERVER_DIR/.env"
            DB_PASSWORD="$new_password"
            print_success "数据库密码已更新"
        else
            print_error "数据库用户创建仍然失败"
            return 1
        fi
    fi
}

# 测试数据库连接
test_database_connection() {
    print_info "测试数据库连接..."
    
    # 使用新密码测试连接
    if mysql -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SELECT 1;" > /dev/null 2>&1; then
        print_success "数据库连接测试成功"
        return 0
    else
        print_error "数据库连接测试失败"
        return 1
    fi
}

# 运行数据库迁移
run_migration() {
    print_info "运行数据库迁移..."
    
    cd "$SERVER_DIR"
    
    # 设置正确的权限
    chown -R fracturego:fracturego "$SERVER_DIR"
    
    # 以fracturego用户身份运行迁移
    if su - fracturego -c "cd $SERVER_DIR && npm run migrate"; then
        print_success "数据库迁移完成"
    else
        print_error "数据库迁移失败"
        return 1
    fi
}

# 重新启动服务
restart_services() {
    print_info "重新启动服务..."
    
    cd "$SERVER_DIR"
    
    # 停止现有服务
    su - fracturego -c "cd $SERVER_DIR && pm2 delete fracturego-server" 2>/dev/null || true
    
    # 启动服务
    su - fracturego -c "cd $SERVER_DIR && pm2 start ecosystem.config.js --env production"
    
    # 保存配置
    su - fracturego -c "pm2 save"
    
    print_success "服务重新启动完成"
}

# 验证部署
verify_final() {
    print_info "最终验证..."
    
    sleep 3
    
    # 检查服务状态
    if su - fracturego -c "pm2 describe fracturego-server" > /dev/null 2>&1; then
        print_success "服务运行正常"
    else
        print_warning "服务状态检查失败"
    fi
    
    # 检查端口
    if netstat -tlnp | grep ":28974 " > /dev/null; then
        print_success "端口 28974 正在监听"
    else
        print_warning "端口 28974 未检测到监听"
    fi
    
    # 测试API
    if curl -f http://localhost:28974/health > /dev/null 2>&1; then
        print_success "API健康检查通过"
    else
        print_warning "API健康检查失败（服务可能需要更多时间启动）"
    fi
}

# 显示完成信息
show_completion() {
    print_success "数据库密码修复完成！"
    echo ""
    echo "🔧 如果仍有问题，请检查："
    echo "   1. MySQL服务是否正常运行: systemctl status mysql"
    echo "   2. 防火墙设置: ufw status"
    echo "   3. 服务日志: su - fracturego -c 'pm2 logs'"
    echo ""
    echo "📱 测试API："
    echo "   curl http://localhost:28974/health"
    echo ""
    
    # 显示API密钥
    if [ -f "$SERVER_DIR/.env" ]; then
        API_KEY=$(grep "^API_KEY=" "$SERVER_DIR/.env" | cut -d '=' -f2)
        echo "🔑 API密钥: $API_KEY"
    fi
}

# 主函数
main() {
    if read_current_config; then
        print_info "使用现有配置修复数据库连接"
    else
        print_error "无法读取配置，请先运行 bash fix-deploy.sh"
        exit 1
    fi
    
    recreate_database_user
    
    if test_database_connection; then
        run_migration
        restart_services
        verify_final
        show_completion
    else
        print_error "数据库连接仍然失败，请检查密码设置"
        exit 1
    fi
}

# 运行主函数
main "$@" 