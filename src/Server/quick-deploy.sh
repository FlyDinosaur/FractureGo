#!/bin/bash

# FractureGo服务器快速部署脚本
# 适用于已配置SSH的Linux服务器

set -e

echo "🚀 FractureGo服务器快速部署"
echo "=================================="

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

# 检查SSH配置
check_ssh_config() {
    print_info "检查SSH配置..."
    
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "GitHub SSH连接正常"
        return 0
    else
        print_error "GitHub SSH连接失败"
        print_warning "正在尝试自动配置SSH..."
        
        # 尝试自动下载和运行SSH配置脚本
        if wget -q https://raw.githubusercontent.com/FlyDinosaur/FractureGo-Server/main/scripts/setup-github-ssh.sh; then
            chmod +x setup-github-ssh.sh
            print_info "已下载SSH配置脚本，请运行: bash setup-github-ssh.sh"
            print_info "配置完成后，请重新运行此部署脚本"
            exit 1
        else
            print_error "无法下载SSH配置脚本"
            echo "请手动配置SSH密钥或使用Token方式"
            return 1
        fi
    fi
}

# 克隆仓库（使用SSH）
clone_repository() {
    print_info "使用SSH克隆FractureGo服务器代码..."
    
    # 如果目录已存在，先备份
    if [ -d "FractureGo-Server" ]; then
        backup_dir="FractureGo-Server-backup-$(date +%Y%m%d-%H%M%S)"
        print_info "备份现有目录到: $backup_dir"
        mv FractureGo-Server "$backup_dir"
    fi
    
    # 使用SSH URL克隆
    if git clone git@github.com:FlyDinosaur/FractureGo-Server.git; then
        print_success "代码克隆完成"
        return 0
    else
        print_error "代码克隆失败"
        return 1
    fi
}

# 运行部署
run_deployment() {
    print_info "进入项目目录并运行部署..."
    
    cd FractureGo-Server
    
    # 给脚本执行权限
    chmod +x deploy.sh
    
    print_info "开始运行部署脚本..."
    print_warning "注意：部署脚本会要求输入数据库密码等信息"
    
    # 运行部署脚本
    bash deploy.sh
}

# 主函数
main() {
    print_info "开始快速部署流程..."
    
    # 检查SSH配置
    if ! check_ssh_config; then
        exit 1
    fi
    
    # 克隆仓库
    if ! clone_repository; then
        exit 1
    fi
    
    # 运行部署
    run_deployment
    
    print_success "快速部署完成！"
}

# 运行主函数
main "$@" 