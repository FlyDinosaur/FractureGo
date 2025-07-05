//
//  HandGestureDetector.swift
//  FractureGo
//
//  Created by AI Assistant
//

import Foundation
import MediaPipeTasksVision

/// 手势检测器 - 专门用于检测握拳状态
class HandGestureDetector {
    
    /// 检测握拳状态 - 更宽松的握拳检测算法
    /// - Parameter landmarks: 手部21个关键点数据
    /// - Returns: 是否为握拳状态
    func isHandClenched(landmarks: [NormalizedLandmark]) -> Bool {
        guard landmarks.count >= 21 else {
            print("❌ 手部关键点数量不足: \(landmarks.count)")
            return false
        }
        
        print("🔍 开始握拳检测分析...")
        
        // 手部关键点索引定义
        let wrist = landmarks[0]           // 手腕
        let thumbTip = landmarks[4]        // 拇指尖
        let thumbMCP = landmarks[2]        // 拇指掌指关节
        let indexTip = landmarks[8]        // 食指尖
        let indexMCP = landmarks[5]        // 食指掌指关节
        let indexPIP = landmarks[6]        // 食指近指关节
        let middleTip = landmarks[12]      // 中指尖
        let middleMCP = landmarks[9]       // 中指掌指关节
        let middlePIP = landmarks[10]      // 中指近指关节
        let ringTip = landmarks[16]        // 无名指尖
        let ringMCP = landmarks[13]        // 无名指掌指关节
        let ringPIP = landmarks[14]        // 无名指近指关节
        let pinkyTip = landmarks[20]       // 小指尖
        let pinkyMCP = landmarks[17]       // 小指掌指关节
        let pinkyPIP = landmarks[18]       // 小指近指关节
        
        var fistScore: Float = 0.0
        let maxScore: Float = 5.0
        
        // 1. 检查食指弯曲程度
        let indexCurled = isFingerCurled(
            tip: indexTip,
            pip: indexPIP,
            mcp: indexMCP,
            wrist: wrist
        )
        if indexCurled { fistScore += 1.0 }
        print("👆 食指弯曲检测: \(indexCurled ? "弯曲" : "伸直")")
        
        // 2. 检查中指弯曲程度
        let middleCurled = isFingerCurled(
            tip: middleTip,
            pip: middlePIP,
            mcp: middleMCP,
            wrist: wrist
        )
        if middleCurled { fistScore += 1.0 }
        print("🖕 中指弯曲检测: \(middleCurled ? "弯曲" : "伸直")")
        
        // 3. 检查无名指弯曲程度
        let ringCurled = isFingerCurled(
            tip: ringTip,
            pip: ringPIP,
            mcp: ringMCP,
            wrist: wrist
        )
        if ringCurled { fistScore += 1.0 }
        print("💍 无名指弯曲检测: \(ringCurled ? "弯曲" : "伸直")")
        
        // 4. 检查小指弯曲程度
        let pinkyCurled = isFingerCurled(
            tip: pinkyTip,
            pip: pinkyPIP,
            mcp: pinkyMCP,
            wrist: wrist
        )
        if pinkyCurled { fistScore += 1.0 }
        print("🤙 小指弯曲检测: \(pinkyCurled ? "弯曲" : "伸直")")
        
        // 5. 检查拇指是否内收（握拳时拇指通常会内收）
        let thumbTucked = isThumbTucked(
            thumbTip: thumbTip,
            thumbMCP: thumbMCP,
            indexMCP: indexMCP,
            middleMCP: middleMCP
        )
        if thumbTucked { fistScore += 1.0 }
        print("👍 拇指内收检测: \(thumbTucked ? "内收" : "外展")")
        
        // 握拳判断：至少3个手指弯曲即认为是握拳（比MediaPipe更宽松）
        let fistThreshold: Float = 3.0
        let isFist = fistScore >= fistThreshold
        
        print("📊 握拳得分: \(fistScore)/\(maxScore), 阈值: \(fistThreshold), 结果: \(isFist ? "握拳" : "张开")")
        
        return isFist
    }
    
    /// 检查手指是否弯曲
    private func isFingerCurled(tip: NormalizedLandmark, pip: NormalizedLandmark, mcp: NormalizedLandmark, wrist: NormalizedLandmark) -> Bool {
        // 计算指尖到手腕的距离
        let tipToWristDistance = distance(tip, wrist)
        // 计算掌指关节到手腕的距离
        let mcpToWristDistance = distance(mcp, wrist)
        
        // 如果指尖距离手腕比掌指关节距离手腕近很多，说明手指弯曲
        let curledRatio = tipToWristDistance / mcpToWristDistance
        
        // 同时检查指尖是否在近指关节下方（Y坐标更大，因为坐标系原点在左上角）
        let tipBelowPIP = tip.y > pip.y
        
        // 优化：增加角度检测，更准确判断弯曲
        let angle = calculateFingerAngle(tip: tip, pip: pip, mcp: mcp)
        let angleThreshold: Float = 160.0 // 角度小于160度认为弯曲
        
        // 综合判断：比例小于1.3，指尖在近指关节下方，且角度小于阈值
        return curledRatio < 1.3 && tipBelowPIP && angle < angleThreshold
    }
    
    /// 检查拇指是否内收
    private func isThumbTucked(thumbTip: NormalizedLandmark, thumbMCP: NormalizedLandmark, indexMCP: NormalizedLandmark, middleMCP: NormalizedLandmark) -> Bool {
        // 计算拇指尖到食指和中指掌指关节中点的距离
        let midPointX = (indexMCP.x + middleMCP.x) / 2
        let midPointY = (indexMCP.y + middleMCP.y) / 2
        
        let thumbToMidDistance = sqrt(pow(thumbTip.x - midPointX, 2) + pow(thumbTip.y - midPointY, 2))
        let thumbMCPToMidDistance = sqrt(pow(thumbMCP.x - midPointX, 2) + pow(thumbMCP.y - midPointY, 2))
        
        // 优化：增加拇指与手掌平面的关系检测
        let thumbCrossed = thumbTip.x > indexMCP.x && thumbTip.x < middleMCP.x
        
        // 如果拇指尖比拇指掌指关节更靠近其他手指，且拇指横跨手掌，说明拇指内收
        return (thumbToMidDistance < thumbMCPToMidDistance * 1.2) || thumbCrossed
    }
    
    /// 计算手指角度（优化的角度计算）
    private func calculateFingerAngle(tip: NormalizedLandmark, pip: NormalizedLandmark, mcp: NormalizedLandmark) -> Float {
        // 计算两个向量：pip->mcp 和 pip->tip
        let vector1 = (x: mcp.x - pip.x, y: mcp.y - pip.y)
        let vector2 = (x: tip.x - pip.x, y: tip.y - pip.y)
        
        // 计算向量的模长
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
        
        // 避免除零错误
        guard magnitude1 > 0 && magnitude2 > 0 else { return 180.0 }
        
        // 计算点积
        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        
        // 计算夹角的余弦值
        let cosAngle = dotProduct / (magnitude1 * magnitude2)
        
        // 确保余弦值在有效范围内
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        
        // 计算角度（弧度转角度）
        let angleRadians = acos(clampedCos)
        let angleDegrees = angleRadians * 180.0 / Float.pi
        
        return angleDegrees
    }
    
    /// 计算两点之间的距离
    private func distance(_ point1: NormalizedLandmark, _ point2: NormalizedLandmark) -> Float {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
}