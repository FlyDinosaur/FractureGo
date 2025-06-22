const { validationResult } = require('express-validator');
const db = require('../config/database');

class SignInController {
    // 获取用户签到统计数据
    async getSignInStats(req, res) {
        try {
            const userId = req.user.id;

            // 获取签到统计数据
            const [stats] = await db.query(`
                SELECT 
                    total_sign_days,
                    current_continuous_days,
                    max_continuous_days,
                    total_reward_points
                FROM user_sign_stats 
                WHERE user_id = ?
            `, [userId]);

            if (!stats) {
                // 如果没有统计记录，初始化一个
                await db.query(`
                    INSERT INTO user_sign_stats (
                        user_id, total_sign_days, current_continuous_days, max_continuous_days, total_reward_points
                    ) VALUES (?, 0, 0, 0, 0)
                `, [userId]);

                return res.json({
                    success: true,
                    data: {
                        totalDays: 0,
                        currentStreak: 0,
                        longestStreak: 0,
                        totalRewards: 0
                    }
                });
            }

            res.json({
                success: true,
                data: {
                    totalDays: stats.total_sign_days,
                    currentStreak: stats.current_continuous_days,
                    longestStreak: stats.max_continuous_days,
                    totalRewards: stats.total_reward_points
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

    // 获取指定月份的签到数据
    async getMonthSignIns(req, res) {
        try {
            const userId = req.user.id;
            const { year, month } = req.query;

            if (!year || !month) {
                return res.status(400).json({
                    success: false,
                    message: '缺少年份或月份参数'
                });
            }

            // 获取指定月份的签到记录
            const signIns = await db.query(`
                SELECT 
                    id,
                    DAY(sign_date) as day,
                    sign_type,
                    reward_points,
                    created_at as signedAt
                FROM user_sign_ins 
                WHERE user_id = ? 
                AND YEAR(sign_date) = ? 
                AND MONTH(sign_date) = ?
                ORDER BY sign_date ASC
            `, [userId, year, month]);

            // 转换数据格式
            const formattedSignIns = signIns.map(record => ({
                id: record.id,
                day: record.day,
                signInType: record.sign_type,
                rewardPoints: record.reward_points,
                signedAt: record.signedAt
            }));

            res.json({
                success: true,
                data: {
                    year: parseInt(year),
                    month: parseInt(month),
                    signIns: formattedSignIns
                }
            });

        } catch (error) {
            console.error('获取月份签到数据错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }

    // 执行签到
    async signIn(req, res) {
        try {
            const userId = req.user.id;
            const today = new Date();
            const todayString = today.toISOString().split('T')[0];

            // 检查今天是否已经签到
            const [existingSignIn] = await db.query(`
                SELECT id FROM user_sign_ins 
                WHERE user_id = ? AND sign_date = ?
            `, [userId, todayString]);

            if (existingSignIn) {
                return res.status(400).json({
                    success: false,
                    message: '今天已经签到过了'
                });
            }

            // 开始事务
            await db.transaction(async (connection) => {
                // 获取当前统计数据
                const [currentStats] = await connection.execute(`
                    SELECT * FROM user_sign_stats WHERE user_id = ?
                `, [userId]);

                let stats = currentStats;
                if (!stats) {
                    // 初始化统计数据
                    await connection.execute(`
                        INSERT INTO user_sign_stats (
                            user_id, total_sign_days, current_continuous_days, max_continuous_days, total_reward_points
                        ) VALUES (?, 0, 0, 0, 0)
                    `, [userId]);
                    stats = {
                        total_sign_days: 0,
                        current_continuous_days: 0,
                        max_continuous_days: 0,
                        total_reward_points: 0
                    };
                }

                // 检查是否连续签到
                const yesterday = new Date(today);
                yesterday.setDate(yesterday.getDate() - 1);
                const yesterdayString = yesterday.toISOString().split('T')[0];

                const [yesterdaySignIn] = await connection.execute(`
                    SELECT id FROM user_sign_ins 
                    WHERE user_id = ? AND sign_date = ?
                `, [userId, yesterdayString]);

                let newCurrentStreak;
                if (yesterdaySignIn) {
                    // 连续签到
                    newCurrentStreak = stats.current_continuous_days + 1;
                } else {
                    // 重新开始
                    newCurrentStreak = 1;
                }

                // 确定签到类型和奖励
                let signType = 'normal';
                let rewardPoints = 10; // 基础奖励

                // 根据连续签到天数给予不同奖励
                if (newCurrentStreak % 30 === 0) {
                    signType = 'target';
                    rewardPoints = 100;
                } else if (newCurrentStreak % 7 === 0) {
                    signType = 'gift';
                    rewardPoints = 50;
                } else if (newCurrentStreak >= 7) {
                    rewardPoints = 20; // 连续一周以上奖励更多
                }

                // 插入签到记录
                const [signInResult] = await connection.execute(`
                    INSERT INTO user_sign_ins (user_id, sign_date, sign_time, sign_type, reward_points)
                    VALUES (?, ?, CURTIME(), ?, ?)
                `, [userId, todayString, signType, rewardPoints]);

                // 更新统计数据
                const newTotalDays = stats.total_sign_days + 1;
                const newLongestStreak = Math.max(stats.max_continuous_days, newCurrentStreak);
                const newTotalRewards = stats.total_reward_points + rewardPoints;

                await connection.execute(`
                    UPDATE user_sign_stats SET
                        total_sign_days = ?,
                        current_continuous_days = ?,
                        max_continuous_days = ?,
                        total_reward_points = ?,
                        last_sign_date = ?,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE user_id = ?
                `, [newTotalDays, newCurrentStreak, newLongestStreak, newTotalRewards, todayString, userId]);

                // 返回签到结果
                res.json({
                    success: true,
                    data: {
                        signInId: signInResult.insertId,
                        day: today.getDate(),
                        signInType: signType,
                        rewardPoints: rewardPoints,
                        currentStreak: newCurrentStreak,
                        totalRewards: newTotalRewards,
                        message: `签到成功！获得 ${rewardPoints} 积分，连续签到 ${newCurrentStreak} 天`
                    }
                });
            });

        } catch (error) {
            console.error('签到错误:', error);
            res.status(500).json({
                success: false,
                message: '服务器内部错误'
            });
        }
    }
}

module.exports = new SignInController(); 