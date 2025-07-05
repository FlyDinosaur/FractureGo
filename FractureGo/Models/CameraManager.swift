//
//  CameraManager.swift
//  FractureGo
//
//  Created by AI Assistant
//

import Foundation
import AVFoundation
import MediaPipeTasksVision
import UIKit

/// 摄像头管理器 - 处理摄像头预览和手势检测
class CameraManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let handGestureDetector = HandGestureDetector()
    private var handLandmarker: HandLandmarker?
    
    // 手势状态
    @Published var isHandClenched: Bool = false
    @Published var handLandmarks: [NormalizedLandmark] = []
    
    // 回调
    var onHandGestureDetected: ((Bool) -> Void)?
    
    override init() {
        super.init()
        setupHandLandmarker()
    }
    
    /// 设置手部关键点检测器
    private func setupHandLandmarker() {
        guard let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task") else {
            print("❌ 找不到手部关键点检测模型文件")
            return
        }
        
        let options = HandLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numHands = 1
        options.minHandDetectionConfidence = 0.5
        options.minHandPresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        
        // 设置结果回调
        options.handLandmarkerLiveStreamDelegate = self
        
        do {
            handLandmarker = try HandLandmarker(options: options)
            print("✅ 手部关键点检测器初始化成功")
        } catch {
            print("❌ 手部关键点检测器初始化失败: \(error)")
        }
    }
    
    /// 启动摄像头会话
    func startSession() {
        guard captureSession == nil else {
            print("⚠️ 摄像头会话已经存在，跳过启动")
            return
        }
        
        print("🎥 开始启动摄像头会话...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCaptureSession()
        }
    }
    
    /// 停止摄像头会话
    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
    }
    
    /// 设置摄像头捕获会话
    private func setupCaptureSession() {
        print("🔧 开始设置摄像头捕获会话...")
        
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        print("📱 设置会话预设为 medium")
        
        // 添加前置摄像头输入
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: frontCamera) else {
            print("❌ 无法访问前置摄像头")
            return
        }
        
        print("✅ 成功获取前置摄像头设备: \(frontCamera.localizedName)")
        
        if session.canAddInput(input) {
            session.addInput(input)
            print("✅ 成功添加摄像头输入")
        } else {
            print("❌ 无法添加摄像头输入到会话")
            return
        }
        
        // 添加视频输出
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        print("🎬 配置视频输出设置")
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
            print("✅ 成功添加视频输出")
        } else {
            print("❌ 无法添加视频输出到会话")
            return
        }
        
        // 创建预览层
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        print("🖼️ 创建预览层")
        
        DispatchQueue.main.async {
            self.previewLayer = preview
            self.captureSession = session
            session.startRunning()
            print("✅ 摄像头会话启动成功，开始运行")
            print("📊 会话状态: \(session.isRunning ? "运行中" : "已停止")")
        }
    }
    
    /// 获取预览层
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let handLandmarker = handLandmarker else { return }
        
        // 转换为MPImage
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        do {
            let mpImage = try MPImage(pixelBuffer: pixelBuffer)
            
            // 获取时间戳
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let timestampMs = Int(CMTimeGetSeconds(timestamp) * 1000)
            
            // 异步检测手部关键点
            try handLandmarker.detectAsync(image: mpImage, timestampInMilliseconds: timestampMs)
        } catch {
             print("❌ 手部关键点检测失败: \(error)")
         }
    }
}

// MARK: - HandLandmarkerLiveStreamDelegate
extension CameraManager: HandLandmarkerLiveStreamDelegate {
    func handLandmarker(_ handLandmarker: HandLandmarker, didFinishDetection result: HandLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        if let error = error {
            print("❌ 手部检测错误: \(error)")
            return
        }
        
        guard let result = result else {
            print("⚠️ 手部检测结果为空")
            DispatchQueue.main.async {
                self.isHandClenched = false
                self.handLandmarks = []
                self.onHandGestureDetected?(false)
            }
            return
        }
        
        if result.landmarks.isEmpty {
            print("⚠️ 未检测到手部关键点")
            DispatchQueue.main.async {
                self.isHandClenched = false
                self.handLandmarks = []
                self.onHandGestureDetected?(false)
            }
            return
        }
        
        let firstHand = result.landmarks[0]
        print("✅ 检测到手部关键点，数量: \(firstHand.count)")
        
        // 检测握拳状态
        let isClenched = handGestureDetector.isHandClenched(landmarks: firstHand)
        print("🤜 握拳检测结果: \(isClenched ? "握拳" : "张开")")
        
        // 打印关键点位置用于调试
        if firstHand.count >= 21 {
            let wrist = firstHand[0]
            let thumbTip = firstHand[4]
            let indexTip = firstHand[8]
            let middleTip = firstHand[12]
            print("📍 关键点位置 - 手腕: (\(String(format: "%.3f", wrist.x)), \(String(format: "%.3f", wrist.y))), 拇指尖: (\(String(format: "%.3f", thumbTip.x)), \(String(format: "%.3f", thumbTip.y))), 食指尖: (\(String(format: "%.3f", indexTip.x)), \(String(format: "%.3f", indexTip.y))), 中指尖: (\(String(format: "%.3f", middleTip.x)), \(String(format: "%.3f", middleTip.y)))")
        }
        
        DispatchQueue.main.async {
            self.isHandClenched = isClenched
            self.handLandmarks = firstHand
            self.onHandGestureDetected?(isClenched)
        }
    }
}