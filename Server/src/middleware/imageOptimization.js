const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;

// 图片优化中间件
const imageOptimization = async (req, res, next) => {
    try {
        // 只处理图片请求
        if (!req.path.match(/\.(jpg|jpeg|png|webp)$/i)) {
            return next();
        }

        // 获取查询参数
        const { width, height, quality = 80, format } = req.query;
        
        // 如果没有优化参数，直接返回原图
        if (!width && !height && !format && quality == 80) {
            return next();
        }

        // 构建原始文件路径
        const originalPath = path.join(__dirname, '..', '..', 'uploads', req.path.replace('/uploads/', ''));
        
        // 检查原始文件是否存在
        try {
            await fs.access(originalPath);
        } catch (error) {
            return next(); // 文件不存在，继续到下一个中间件
        }

        // 生成缓存键
        const cacheKey = `${req.path}_w${width || 'auto'}_h${height || 'auto'}_q${quality}_f${format || 'original'}`;
        const cacheDir = path.join(__dirname, '..', '..', 'uploads', 'cache');
        const cachePath = path.join(cacheDir, cacheKey.replace(/[\/\\]/g, '_'));

        // 确保缓存目录存在
        try {
            await fs.mkdir(cacheDir, { recursive: true });
        } catch (error) {
            console.error('创建缓存目录失败:', error);
        }

        // 检查缓存文件是否存在
        let useCache = false;
        try {
            await fs.access(cachePath);
            useCache = true;
        } catch (error) {
            // 缓存文件不存在，需要创建
        }

        let outputPath = cachePath;

        if (!useCache) {
            // 处理图片
            let sharpInstance = sharp(originalPath);

            // 调整尺寸
            if (width || height) {
                sharpInstance = sharpInstance.resize(
                    width ? parseInt(width) : null,
                    height ? parseInt(height) : null,
                    {
                        fit: 'inside',
                        withoutEnlargement: true
                    }
                );
            }

            // 设置质量和格式，优先使用JPEG以提高兼容性
            const targetFormat = format || 'jpeg';
            
            switch (targetFormat) {
                case 'jpg':
                case 'jpeg':
                    sharpInstance = sharpInstance.jpeg({ 
                        quality: parseInt(quality),
                        progressive: true,
                        mozjpeg: true
                    });
                    break;
                case 'png':
                    sharpInstance = sharpInstance.png({ 
                        quality: parseInt(quality),
                        compressionLevel: 8
                    });
                    break;
                case 'webp':
                    sharpInstance = sharpInstance.webp({ 
                        quality: parseInt(quality),
                        effort: 4
                    });
                    break;
                default:
                    // 默认使用JPEG
                    sharpInstance = sharpInstance.jpeg({ 
                        quality: parseInt(quality),
                        progressive: true
                    });
                    break;
            }

            // 保存处理后的图片
            await sharpInstance.toFile(cachePath);
        }

        // 设置正确的Content-Type
        const ext = format || 'jpeg';
        const mimeTypes = {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'webp': 'image/webp'
        };
        
        res.setHeader('Content-Type', mimeTypes[ext] || 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=86400, immutable'); // 缓存24小时
        res.setHeader('Vary', 'Accept-Encoding');
        res.setHeader('X-Image-Optimized', 'true');
        
        // 返回处理后的图片
        const imageBuffer = await fs.readFile(outputPath);
        res.send(imageBuffer);

    } catch (error) {
        console.error('图片处理错误:', error);
        next(); // 出错时返回原图
    }
};

module.exports = { imageOptimization }; 