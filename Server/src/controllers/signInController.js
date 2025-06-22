const { validationResult } = require('express-validator');
const db = require('../config/database');

class SignInController {
    // 用户签到
    async signIn(req, res) {
        try {
            const errors = validationResult(req);
            if (!errors.isEmpty()) {
                return res.status(400).json({
                    success: false,
                    message: '输入验证失败',
                    errors: errors.array()
                });
            }

            const userId = req.user.userId;
            const { signType = 'normal', note = '' } = req.body;
            const today = new Date().toISOString().split('T')[0];
            const currentTime = new Date().toTimeString().split(' ')[0];

            // 检查今天是否已经签到
            const [existingSignIn] = await db.query(
                'SELECT id FROM user_sign_ins WHERE user_id = ? AND sign_date = ?',
                [userId, today]
            );

            if (existingSignIn) {
                return res.status(409).json({
                    success: false,
                    message: '今日已签到'
                });
            }

            // 获取用户签到统计
            let [signStats] = await db.query(
                'SELECT * FROM user_sign_stats WHERE user_id = ?',
                [userId]
            );

            // 如果没有统计记录，创建一个
            if (!signStats) {
                await db.query(
                    'INSERT INTO user_sign_stats (user_id) VALUES (?)',
                    [userId]
                );
                signStats = {
                    user_id: userId,
                    total_sign_days: 0,
                    current_continuous_days: 0,
                    max_continuous_days: 0,
                    total_reward_points: 0,
                    last_sign_date: null
                };
            }

            // 计算连续签到天数
            let continuousDays = 1;
            if (signStats.last_sign_date) {
                const lastSignDate = new Date(signStats.last_sign_date);
                const todayDate = new Date(today);
                const diffTime = todayDate - lastSignDate;
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                if (diffDays === 1) {
                    // 连续签到
                    continuousDays = signStats.current_continuous_days + 1;
                } else {
                    // 中断了，重新开始
                    continuousDays = 1;
                }
            }

            // 计算奖励积分
            let rewardPoints = 10; // 基础积分
            if (signType === 'gift') {
                rewardPoints = 50; // 礼盒签到
            } else if (signType === 'target') {
                rewardPoints = 100; // 目标达成
            }

            // 连续签到奖励
            if (continuousDays >= 7) {
                rewardPoints += Math.floor(continuousDays / 7) * 20;
            }

            // 使用事务处理签到
            await db.transaction(async (connection) => {
                // 插入签到记录
                await connection.execute(
                    `INSERT INTO user_sign_ins 
                     (user_id, sign_date, sign_time, sign_type, reward_points, continuous_days, note)
                     VALUES (?, ?, ?, ?, ?, ?, ?)`,
                    [userId, today, currentTime, signType, rewardPoints, continuousDays, note]
                );

                // 更新签到统计
                const newTotalDays = signStats.total_sign_days + 1;
                const newTotalPoints = signStats.total_reward_points + rewardPoints;
                const newMaxContinuous = Math.max(signStats.max_continuous_days, continuousDays);

                await connection.execute(
                    `UPDATE user_sign_stats 
                     SET total_sign_days = ?, 
                         current_continuous_days = ?, 
                         max_continuous_days = ?, 
                         total_reward_points = ?, 
                         last_sign_date = ?,
                         updated_at = CURRENT_TIMESTAMP
                     WHERE user_id = ?`,
                    [newTotalDays, continuousDays, newMaxContinuous, newTotalPoints, today, userId]
                );
            });

            res.json({
                success: true,
                message: '签到成功',
                data: {
                    signDate: today,
                    signType,
                    rewardPoints,
                    continuousDays,
                    totalSignDays: signStats.total_sign_days + 1
                }
            });

        } catch (error) {
            console.error('签到错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取签到数据
    async getSignInData(req, res) {
        try {
            const userId = req.user.userId;
            const { year, month } = req.query;

            if (!year || !month) {
                return res.status(400).json({
                    success: false,
                    message: '请提供年份和月份'
                });
            }

            // 构建日期范围
            const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
            const endDate = new Date(year, month, 0).toISOString().split('T')[0]; // 月份最后一天

            // 获取指定月份的签到记录
            const signInRecords = await db.query(
                `SELECT sign_date, sign_type, reward_points, continuous_days
                 FROM user_sign_ins 
                 WHERE user_id = ? AND sign_date BETWEEN ? AND ?
                 ORDER BY sign_date`,
                [userId, startDate, endDate]
            );

            // 获取签到统计
            const [signStats] = await db.query(
                'SELECT * FROM user_sign_stats WHERE user_id = ?',
                [userId]
            );

            // 组织返回数据
            const signedDays = [];
            const giftDays = [];
            const targetDays = [];

            signInRecords.forEach(record => {
                const day = new Date(record.sign_date).getDate();
                if (record.sign_type === 'gift') {
                    giftDays.push(day);
                } else if (record.sign_type === 'target') {
                    targetDays.push(day);
                } else {
                    signedDays.push(day);
                }
            });

            res.json({
                success: true,
                data: {
                    year: parseInt(year),
                    month: parseInt(month),
                    signedDays,
                    giftDays,
                    targetDays,
                    continuousDays: signStats?.current_continuous_days || 0,
                    totalSignDays: signStats?.total_sign_days || 0,
                    totalRewardPoints: signStats?.total_reward_points || 0
                }
            });

        } catch (error) {
            console.error('获取签到数据错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 获取签到统计
    async getSignInStats(req, res) {
        try {
            const userId = req.user.userId;

            const [signStats] = await db.query(
                'SELECT * FROM user_sign_stats WHERE user_id = ?',
                [userId]
            );

            // 获取最近7天的签到记录
            const recentSignIns = await db.query(
                `SELECT sign_date, sign_type, reward_points
                 FROM user_sign_ins 
                 WHERE user_id = ? AND sign_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
                 ORDER BY sign_date DESC`,
                [userId]
            );

            res.json({
                success: true,
                data: {
                    totalSignDays: signStats?.total_sign_days || 0,
                    currentContinuousDays: signStats?.current_continuous_days || 0,
                    maxContinuousDays: signStats?.max_continuous_days || 0,
                    totalRewardPoints: signStats?.total_reward_points || 0,
                    lastSignDate: signStats?.last_sign_date,
                    recentSignIns
                }
            });

        } catch (error) {
            console.error('获取签到统计错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 检查今日是否已签到
    async checkTodaySignIn(req, res) {
        try {
            const userId = req.user.userId;
            const today = new Date().toISOString().split('T')[0];

            const [signIn] = await db.query(
                'SELECT * FROM user_sign_ins WHERE user_id = ? AND sign_date = ?',
                [userId, today]
            );

            res.json({
                success: true,
                data: {
                    hasSigned: !!signIn,
                    signData: signIn || null
                }
            });

        } catch (error) {
            console.error('检查签到状态错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }
}

module.exports = new SignInController(); 