const mysql = require('mysql2/promise');
require('dotenv').config();

class Database {
    constructor() {
        this.pool = null;
        this.init();
    }

    async init() {
        try {
            this.pool = mysql.createPool({
                host: process.env.DB_HOST || 'localhost',
                port: process.env.DB_PORT || 3306,
                user: process.env.DB_USER || 'fracturego_user',
                password: process.env.DB_PASSWORD,
                database: process.env.DB_NAME || 'fracturego_db',
                waitForConnections: true,
                connectionLimit: 10,
                queueLimit: 0,
                charset: 'utf8mb4',
                timezone: '+08:00',
                ssl: false
            });

            // 测试连接
            const connection = await this.pool.getConnection();
            console.log('✅ 数据库连接成功');
            connection.release();
        } catch (error) {
            console.error('❌ 数据库连接失败:', error.message);
            process.exit(1);
        }
    }

    async query(sql, params = []) {
        try {
            const [rows] = await this.pool.execute(sql, params);
            return rows;
        } catch (error) {
            console.error('数据库查询错误:', error.message);
            throw error;
        }
    }

    async transaction(callback) {
        const connection = await this.pool.getConnection();
        await connection.beginTransaction();

        try {
            const result = await callback(connection);
            await connection.commit();
            return result;
        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }
    }

    async close() {
        if (this.pool) {
            await this.pool.end();
            console.log('数据库连接已关闭');
        }
    }
}

module.exports = new Database(); 