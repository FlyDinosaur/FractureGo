const jwt = require('jsonwebtoken');
const db = require('../config/database');

// API密钥验证中间件
const authenticateApiKey = async (req, res, next) => {
    try {
        const apiKey = req.headers['x-api-key'];
        
        if (!apiKey) {
            return res.status(401).json({
                success: false,
                message: '缺少API密钥'
            });
        }

        // 验证API密钥
        const [keyData] = await db.query(
            'SELECT * FROM api_keys WHERE api_key = ? AND is_active = true',
            [apiKey]
        );

        if (!keyData) {
            return res.status(401).json({
                success: false,
                message: '无效的API密钥'
            });
        }

        // 检查密钥是否过期
        if (keyData.expires_at && new Date() > keyData.expires_at) {
            return res.status(401).json({
                success: false,
                message: 'API密钥已过期'
            });
        }

        // 更新最后使用时间
        await db.query(
            'UPDATE api_keys SET last_used_at = CURRENT_TIMESTAMP WHERE id = ?',
            [keyData.id]
        );

        req.apiKey = keyData;
        next();
    } catch (error) {
        console.error('API密钥验证错误:', error);
        res.status(500).json({
            success: false,
            message: '服务器内部错误'
        });
    }
};

// JWT Token验证中间件
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];

        if (!token) {
            return res.status(401).json({
                success: false,
                message: '缺少访问令牌'
            });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // 验证用户是否存在且状态正常
        const [user] = await db.query(
            'SELECT id, phone_number, nickname, user_type, status FROM users WHERE id = ? AND status = "active"',
            [decoded.userId]
        );

        if (!user) {
            return res.status(401).json({
                success: false,
                message: '用户不存在或已被禁用'
            });
        }

        req.user = user;
        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({
                success: false,
                message: '无效的访问令牌'
            });
        }
        
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: '访问令牌已过期'
            });
        }

        console.error('Token验证错误:', error);
        res.status(500).json({
            success: false,
            message: '服务器内部错误'
        });
    }
};

// 权限检查中间件
const requirePermission = (permission) => {
    return (req, res, next) => {
        const apiKey = req.apiKey;
        
        if (!apiKey) {
            return res.status(403).json({
                success: false,
                message: '权限不足'
            });
        }

        // 检查permissions字段是否存在且不为空
        if (!apiKey.permissions) {
            return res.status(403).json({
                success: false,
                message: '权限配置错误'
            });
        }

        let permissions;
        try {
            // 如果permissions已经是数组，直接使用；否则解析JSON
            if (Array.isArray(apiKey.permissions)) {
                permissions = apiKey.permissions;
            } else if (typeof apiKey.permissions === 'string') {
                // 处理空字符串或undefined情况
                if (apiKey.permissions.trim() === '' || apiKey.permissions === 'undefined') {
                    console.error('权限配置为空或undefined:', apiKey.permissions);
                    return res.status(500).json({
                        success: false,
                        message: '权限配置为空'
                    });
                }
                permissions = JSON.parse(apiKey.permissions);
            } else {
                console.error('权限配置类型错误:', typeof apiKey.permissions, apiKey.permissions);
                return res.status(500).json({
                    success: false,
                    message: '权限配置类型错误'
                });
            }
        } catch (error) {
            console.error('权限JSON解析错误:', error);
            console.error('原始权限数据:', apiKey.permissions);
            return res.status(500).json({
                success: false,
                message: '权限配置格式错误'
            });
        }
        
        if (!Array.isArray(permissions) || !permissions.includes(permission)) {
            return res.status(403).json({
                success: false,
                message: `缺少权限: ${permission}`
            });
        }

        next();
    };
};

// 用户类型检查中间件
const requireUserType = (userTypes) => {
    return (req, res, next) => {
        const user = req.user;
        
        if (!user) {
            return res.status(401).json({
                success: false,
                message: '用户未认证'
            });
        }

        const allowedTypes = Array.isArray(userTypes) ? userTypes : [userTypes];
        
        if (!allowedTypes.includes(user.user_type)) {
            return res.status(403).json({
                success: false,
                message: '用户类型权限不足'
            });
        }

        next();
    };
};

module.exports = {
    authenticateApiKey,
    authenticateToken,
    requirePermission,
    requireUserType
}; 