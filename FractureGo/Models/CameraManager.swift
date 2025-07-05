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
        guard captureSession == nil else { return }
        
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
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        // 添加后置摄像头输入
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: backCamera) else {
            print("❌ 无法访问后置摄像头")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // 添加视频输出
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
        }
        
        // 创建预览层
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            self.previewLayer = preview
            self.captureSession = session
            session.startRunning()
            print("✅ 摄像头会话启动成功")
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
        
        guard let result = result,
              let firstHand = result.landmarks.first else {
            // 没有检测到手部
            DispatchQueue.main.async {
                self.isHandClenched = false
                self.handLandmarks = []
                self.onHandGestureDetected?(false)
            }
            return
        }
        
        // 检测握拳状态
        let isClenched = handGestureDetector.isHandClenched(landmarks: firstHand)
        
        DispatchQueue.main.async {
            self.isHandClenched = isClenched
            self.handLandmarks = firstHand
            self.onHandGestureDetected?(isClenched)
        }
    }
}