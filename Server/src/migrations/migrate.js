const db = require('../config/database');

async function createTables() {
    try {
        console.log('🚀 开始创建数据库表...');

        // 创建用户表
        await db.query(`
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                phone_number VARCHAR(20) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                nickname VARCHAR(100) NOT NULL,
                user_type ENUM('patient', 'doctor', 'therapist') NOT NULL,
                birth_date DATE,
                avatar_data LONGTEXT COMMENT '用户头像Base64数据',
                is_wechat_user BOOLEAN DEFAULT FALSE,
                wechat_open_id VARCHAR(100),
                wechat_union_id VARCHAR(100),
                wechat_nickname VARCHAR(100),
                wechat_avatar_url TEXT,
                status ENUM('active', 'inactive', 'banned') DEFAULT 'active',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                last_login_at TIMESTAMP NULL,
                INDEX idx_phone (phone_number),
                INDEX idx_wechat_open_id (wechat_open_id),
                INDEX idx_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 创建训练记录表
        await db.query(`
            CREATE TABLE IF NOT EXISTS training_records (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                training_type ENUM('hand', 'arm', 'leg') NOT NULL,
                level INT NOT NULL,
                score INT DEFAULT 0,
                duration INT NOT NULL COMMENT '训练时长(秒)',
                completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                data JSON COMMENT '训练详细数据',
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_user_training (user_id, training_type),
                INDEX idx_completed_at (completed_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 创建用户进度表
        await db.query(`
            CREATE TABLE IF NOT EXISTS user_progress (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                training_type ENUM('hand', 'arm', 'leg') NOT NULL,
                current_level INT DEFAULT 1,
                max_level_reached INT DEFAULT 1,
                total_training_time INT DEFAULT 0 COMMENT '总训练时长(秒)',
                total_sessions INT DEFAULT 0,
                best_score INT DEFAULT 0,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE KEY unique_user_training (user_id, training_type)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 创建API密钥表
        await db.query(`
            CREATE TABLE IF NOT EXISTS api_keys (
                id INT AUTO_INCREMENT PRIMARY KEY,
                key_name VARCHAR(100) NOT NULL,
                api_key VARCHAR(255) UNIQUE NOT NULL,
                permissions JSON,
                is_active BOOLEAN DEFAULT TRUE,
                expires_at TIMESTAMP NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_used_at TIMESTAMP NULL,
                INDEX idx_api_key (api_key),
                INDEX idx_active (is_active)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 创建请求日志表
        await db.query(`
            CREATE TABLE IF NOT EXISTS request_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                ip_address VARCHAR(45) NOT NULL,
                user_agent TEXT,
                method VARCHAR(10) NOT NULL,
                endpoint VARCHAR(255) NOT NULL,
                status_code INT NOT NULL,
                response_time INT NOT NULL COMMENT '响应时间(毫秒)',
                user_id INT NULL,
                api_key_id INT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
                FOREIGN KEY (api_key_id) REFERENCES api_keys(id) ON DELETE SET NULL,
                INDEX idx_ip_created (ip_address, created_at),
                INDEX idx_endpoint (endpoint),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 创建签到表
        await db.query(`
            CREATE TABLE IF NOT EXISTS user_sign_ins (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                sign_date DATE NOT NULL,
                sign_time TIME NOT NULL,
                sign_type ENUM('normal', 'gift', 'target') DEFAULT 'normal' COMMENT '签到类型：普通、礼盒、目标',
                reward_points INT DEFAULT 0 COMMENT '获得积分',
                continuous_days INT DEFAULT 1 COMMENT '连续签到天数',
                note TEXT COMMENT '签到备注',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE KEY unique_user_date (user_id, sign_date),
                INDEX idx_user_sign_date (user_id, sign_date),
                INDEX idx_sign_date (sign_date)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 创建签到统计表
        await db.query(`
            CREATE TABLE IF NOT EXISTS user_sign_stats (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                total_sign_days INT DEFAULT 0 COMMENT '总签到天数',
                current_continuous_days INT DEFAULT 0 COMMENT '当前连续签到天数',
                max_continuous_days INT DEFAULT 0 COMMENT '最大连续签到天数',
                total_reward_points INT DEFAULT 0 COMMENT '总获得积分',
                last_sign_date DATE NULL COMMENT '最后签到日期',
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                UNIQUE KEY unique_user (user_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        `);

        // 插入默认API密钥
        const defaultApiKey = process.env.API_KEY || 'fracturego_default_api_key_2024';
        await db.query(`
            INSERT IGNORE INTO api_keys (key_name, api_key, permissions, is_active)
            VALUES (?, ?, ?, ?)
        `, [
            'Default Client Key',
            defaultApiKey,
            JSON.stringify(['user:read', 'user:write', 'training:read', 'training:write', 'signin:read', 'signin:write']),
            true
        ]);

        console.log('✅ 数据库表创建完成');
        console.log('📝 默认API密钥:', defaultApiKey);
        
    } catch (error) {
        console.error('❌ 数据库迁移失败:', error.message);
        throw error;
    }
}

// 如果直接运行此文件
if (require.main === module) {
    createTables()
        .then(() => {
            console.log('🎉 数据库迁移完成');
            process.exit(0);
        })
        .catch((error) => {
            console.error('💥 迁移失败:', error);
            process.exit(1);
        });
}

module.exports = { createTables }; 