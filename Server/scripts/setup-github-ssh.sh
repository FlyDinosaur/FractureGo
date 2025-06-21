#!/bin/bash

# GitHub SSH密钥配置脚本
# 用于在Linux服务器上配置私有仓库访问

set -e

echo "🔑 开始配置GitHub SSH密钥..."

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

# 检查是否已有SSH密钥
check_existing_keys() {
    if [ -f ~/.ssh/id_rsa ] || [ -f ~/.ssh/id_ed25519 ]; then
        print_info "发现已存在的SSH密钥"
        ls -la ~/.ssh/
        read -p "是否要创建新的SSH密钥? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "使用现有SSH密钥"
            return 1
        fi
    fi
    return 0
}

# 生成SSH密钥
generate_ssh_key() {
    print_info "生成新的SSH密钥..."
    
    # 获取GitHub邮箱
    read -p "请输入您的GitHub邮箱: " github_email
    
    # 生成ED25519密钥（更安全）
    ssh-keygen -t ed25519 -C "$github_email" -f ~/.ssh/id_ed25519 -N ""
    
    # 如果系统不支持ED25519，使用RSA
    if [ $? -ne 0 ]; then
        print_info "系统不支持ED25519，使用RSA密钥..."
        ssh-keygen -t rsa -b 4096 -C "$github_email" -f ~/.ssh/id_rsa -N ""
    fi
    
    print_success "SSH密钥生成完成"
}

# 启动SSH agent并添加密钥
setup_ssh_agent() {
    print_info "配置SSH agent..."
    
    # 启动ssh-agent
    eval "$(ssh-agent -s)"
    
    # 添加密钥到SSH agent
    if [ -f ~/.ssh/id_ed25519 ]; then
        ssh-add ~/.ssh/id_ed25519
    elif [ -f ~/.ssh/id_rsa ]; then
        ssh-add ~/.ssh/id_rsa
    fi
    
    print_success "SSH agent配置完成"
}

# 配置SSH配置文件
setup_ssh_config() {
    print_info "配置SSH配置文件..."
    
    # 创建SSH配置文件
    cat << EOF > ~/.ssh/config
# GitHub配置
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF

    # 如果使用RSA密钥，更新配置
    if [ ! -f ~/.ssh/id_ed25519 ] && [ -f ~/.ssh/id_rsa ]; then
        sed -i 's/id_ed25519/id_rsa/g' ~/.ssh/config
    fi
    
    # 设置正确的权限
    chmod 600 ~/.ssh/config
    chmod 700 ~/.ssh
    
    print_success "SSH配置文件创建完成"
}

# 显示公钥
show_public_key() {
    print_info "您的SSH公钥如下，请复制并添加到GitHub:"
    echo "=========================================="
    
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        cat ~/.ssh/id_ed25519.pub
    elif [ -f ~/.ssh/id_rsa.pub ]; then
        cat ~/.ssh/id_rsa.pub
    fi
    
    echo "=========================================="
    echo ""
    print_info "添加步骤:"
    echo "1. 复制上面的公钥内容"
    echo "2. 登录GitHub → Settings → SSH and GPG keys"
    echo "3. 点击 'New SSH key'"
    echo "4. 粘贴公钥内容并保存"
    echo ""
}

# 测试GitHub连接
test_github_connection() {
    read -p "是否现在测试GitHub连接? (添加公钥后按y): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "测试GitHub连接..."
        
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            print_success "GitHub SSH连接测试成功!"
        else
            print_error "GitHub连接测试失败，请检查:"
            echo "1. 公钥是否已添加到GitHub"
            echo "2. 网络连接是否正常"
            echo "3. SSH配置是否正确"
        fi
    fi
}

# 主函数
main() {
    # 检查SSH目录
    mkdir -p ~/.ssh
    
    # 检查现有密钥
    if check_existing_keys; then
        generate_ssh_key
    fi
    
    setup_ssh_agent
    setup_ssh_config
    show_public_key
    test_github_connection
    
    print_success "GitHub SSH配置完成!"
    echo "现在可以使用 git clone git@github.com:username/repo.git 克隆私有仓库"
}

# 运行主函数
main "$@" 