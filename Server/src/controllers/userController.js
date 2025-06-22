const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const db = require('../config/database');

class UserController {
    // 用户注册
    async register(req, res) {
        try {
            // 验证输入
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const {
                phoneNumber,
                password,
                nickname,
                userType,
                birthDate,
                isWeChatUser = false,
                wechatOpenId,
                wechatUnionId,
                wechatNickname,
                wechatAvatarUrl
            } = req.body;

            // 处理出生日期格式
            const formattedBirthDate = birthDate ? new Date(birthDate).toISOString().split('T')[0] : null;

            // 检查手机号是否已存在
            const [existingUser] = await db.query(
                'SELECT id FROM users WHERE phone_number = ?',
                [phoneNumber]
            );

            if (existingUser) {
                return res.status(409).json({
                    success: false,
                    message: '手机号已被注册'
                });
            }

            // 如果是微信用户，检查openId是否已存在
            if (isWeChatUser && wechatOpenId) {
                const [existingWeChatUser] = await db.query(
                    'SELECT id FROM users WHERE wechat_open_id = ?',
                    [wechatOpenId]
                );

                if (existingWeChatUser) {
                    return res.status(409).json({
                        success: false,
                        message: '微信账号已被绑定'
                    });
                }
            }

            // 密码加密
            const passwordHash = await bcrypt.hash(password, 12);

            // 创建用户
            const result = await db.query(`
                INSERT INTO users (
                    phone_number, password_hash, nickname, user_type, birth_date,
                    is_wechat_user, wechat_open_id, wechat_union_id, 
                    wechat_nickname, wechat_avatar_url
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `, [
                phoneNumber, 
                passwordHash, 
                nickname, 
                userType, 
                formattedBirthDate,
                isWeChatUser, 
                wechatOpenId || null, 
                wechatUnionId || null,
                wechatNickname || null, 
                wechatAvatarUrl || null
            ]);

            const userId = result.insertId;

            // 初始化用户进度
            await db.query(`
                INSERT INTO user_progress (user_id, training_type, current_level, max_level_reached)
                VALUES 
                (?, 'hand', 1, 1),
                (?, 'arm', 1, 1),
                (?, 'leg', 1, 1)
            `, [userId, userId, userId]);

            // 初始化签到统计
            await db.query(`
                INSERT INTO user_sign_stats (user_id) VALUES (?)
            `, [userId]);

            // 生成JWT Token
            const token = jwt.sign(
                { userId, phoneNumber, userType },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
            );

            res.status(201).json({
                success: true,
                message: '注册成功',
                data: {
                    user: {
                        id: userId,
                        phoneNumber,
                        nickname,
                        userType,
                        birthDate: formattedBirthDate,
                        isWeChatUser
                    },
                    token
                }
            });

        } catch (error) {
            console.error('用户注册错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 用户登录
    async login(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const { phoneNumber, password } = req.body;

            // 查找用户
            const [user] = await db.query(
                'SELECT * FROM users WHERE phone_number = ? AND status = "active"',
                [phoneNumber]
            );

            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: '手机号或密码错误'
                });
            }

            // 验证密码
            const isPasswordValid = await bcrypt.compare(password, user.password_hash);
            if (!isPasswordValid) {
                return res.status(401).json({
                    success: false,
                    message: '手机号或密码错误'
                });
            }

            // 更新最后登录时间
            await db.query(
                'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = ?',
                [user.id]
            );

            // 生成JWT Token
            const token = jwt.sign(
                { userId: user.id, phoneNumber: user.phone_number, userType: user.user_type },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
            );

            res.json({
                success: true,
                message: '登录成功',
                data: {
                    user: {
                        id: user.id,
                        phoneNumber: user.phone_number,
                        nickname: user.nickname,
                        userType: user.user_type,
                        birthDate: user.birth_date,
                        isWeChatUser: user.is_wechat_user,
                        wechatNickname: user.wechat_nickname,
                        wechatAvatarUrl: user.wechat_avatar_url
                    },
                    token
                }
            });

        } catch (error) {
            console.error('用户登录错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 微信登录
    async wechatLogin(req, res) {
        try {
            const { openId, unionId, nickname, avatarUrl } = req.body;

            if (!openId) {
                return res.status(400).json({
                    success: false,
                    message: '缺少微信OpenID'
                });
            }

            // 查找微信用户
            const [user] = await db.query(
                'SELECT * FROM users WHERE wechat_open_id = ? AND status = "active"',
                [openId]
            );

            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: '微信账号尚未绑定，请先注册',
                    data: { openId, unionId, nickname, avatarUrl }
                });
            }

            // 更新微信信息和最后登录时间
            await db.query(`
                UPDATE users SET 
                    wechat_nickname = ?, 
                    wechat_avatar_url = ?,
                    last_login_at = CURRENT_TIMESTAMP 
                WHERE id = ?
            `, [nickname, avatarUrl, user.id]);

            // 生成JWT Token
            const token = jwt.sign(
                { userId: user.id, phoneNumber: user.phone_number, userType: user.user_type },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
            );

            res.json({
                success: true,
                message: '微信登录成功',
                data: {
                    user: {
                        id: user.id,
                        phoneNumber: user.phone_number,
                        nickname: user.nickname,
                        userType: user.user_type,
                        birthDate: user.birth_date,
                        isWeChatUser: true,
                        wechatNickname: nickname,
                        wechatAvatarUrl: avatarUrl
                    },
                    token
                }
            });

        } catch (error) {
            console.error('微信登录错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取用户信息
    async getProfile(req, res) {
        try {
            const userId = req.user.id;

            const [user] = await db.query(`
                SELECT 
                    id, phone_number, nickname, user_type, birth_date,
                    avatar_data, is_wechat_user, wechat_nickname, wechat_avatar_url,
                    created_at, last_login_at
                FROM users 
                WHERE id = ? AND status = "active"
            `, [userId]);

            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: '用户不存在'
                });
            }

            res.json({
                success: true,
                data: { user }
            });

        } catch (error) {
            console.error('获取用户信息错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 更新用户信息
    async updateProfile(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.id;
            const { nickname, birthDate, avatarData } = req.body;

            // 构建更新SQL
            let updateFields = [];
            let updateValues = [];

            if (nickname !== undefined) {
                updateFields.push('nickname = ?');
                updateValues.push(nickname);
            }

            if (birthDate !== undefined) {
                updateFields.push('birth_date = ?');
                updateValues.push(birthDate);
            }

            if (avatarData !== undefined) {
                updateFields.push('avatar_data = ?');
                updateValues.push(avatarData);
            }

            if (updateFields.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: '没有提供要更新的字段'
                });
            }

            updateValues.push(userId);

            await db.query(
                `UPDATE users SET ${updateFields.join(', ')} WHERE id = ?`,
                updateValues
            );

            res.json({
                success: true,
                message: '用户信息更新成功'
            });

        } catch (error) {
            console.error('更新用户信息错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 更新用户头像
    async updateAvatar(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.id;
            const { avatarData } = req.body;

            if (!avatarData) {
                return res.status(400).json({
                    success: false,
                    message: '头像数据不能为空'
                });
            }

            // 验证base64数据格式
            if (!avatarData.startsWith('data:image/')) {
                return res.status(400).json({
                    success: false,
                    message: '头像数据格式不正确'
                });
            }

            await db.query(
                'UPDATE users SET avatar_data = ? WHERE id = ?',
                [avatarData, userId]
            );

            res.json({
                success: true,
                message: '头像更新成功'
            });

        } catch (error) {
            console.error('更新头像错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 修改密码
    async changePassword(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.id;
            const { oldPassword, newPassword } = req.body;

            // 获取当前密码
            const [user] = await db.query(
                'SELECT password_hash FROM users WHERE id = ?',
                [userId]
            );

            // 验证旧密码
            const isOldPasswordValid = await bcrypt.compare(oldPassword, user.password_hash);
            if (!isOldPasswordValid) {
                return res.status(400).json({
                    success: false,
                    message: '原密码错误'
                });
            }

            // 加密新密码
            const newPasswordHash = await bcrypt.hash(newPassword, 12);

            // 更新密码
            await db.query(
                'UPDATE users SET password_hash = ? WHERE id = ?',
                [newPasswordHash, userId]
            );

            res.json({
                success: true,
                message: '密码修改成功'
            });

        } catch (error) {
            console.error('修改密码错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }
}

module.exports = new UserController(); 