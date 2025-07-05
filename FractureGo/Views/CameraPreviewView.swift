//
//  CameraPreviewView.swift
//  FractureGo
//
//  Created by AI Assistant
//

import SwiftUI
import AVFoundation

/// 摄像头预览视图
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 清除之前的预览层
        uiView.layer.sublayers?.removeAll()
        
        // 添加新的预览层
        if let previewLayer = cameraManager.getPreviewLayer() {
            previewLayer.frame = uiView.bounds
            uiView.layer.addSublayer(previewLayer)
        }
    }
}

/// 预览视图的协调器
class CameraPreviewCoordinator: NSObject {
    let parent: CameraPreviewView
    
    init(_ parent: CameraPreviewView) {
        self.parent = parent
    }
}