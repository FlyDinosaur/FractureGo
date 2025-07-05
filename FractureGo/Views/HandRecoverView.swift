//
//  HandRecoverView.swift
//  FractureGo
//
//  Created by LDrain on 2025/7/5.
//

import SwiftUI
import SpriteKit
import ImageIO
import UIKit
import AVFoundation
import MediaPipeTasksVision

// MARK: - 小浣熊精灵类
class RaccoonSprite: SKSpriteNode {
    enum State {
        case running
        case laying
        case movingToBasket
        case inBasket
        case disappeared
    }
    
    private(set) var state: State = .running
    private var runTextures: [SKTexture] = []
    private var layTextures: [SKTexture] = []
    private var currentAnimation: SKAction?
    
    init() {
        super.init(texture: nil, color: .clear, size: CGSize(width: 240, height: 240))
        loadTextures()
        startRunningAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadTextures() {
        // 加载跑步动画纹理
        if let (runTextures, _) = CustomGIFPlayer.loadGIFTexturesFromBundle(named: "hand_cartoon_run") {
            self.runTextures = runTextures
        }
     

        
        // 加载躺下动画纹理
        if let (layTextures, _) = CustomGIFPlayer.loadGIFTexturesFromBundle(named: "hand_cartoon_lay") {
            self.layTextures = layTextures
        }
    }
    
    func startRunningAnimation() {
        guard !runTextures.isEmpty else { return }
        
        state = .running
        currentAnimation?.speed = 0
        removeAction(forKey: "animation")
        
        let animation = SKAction.animate(with: runTextures, timePerFrame: 0.1)
        let repeatAnimation = SKAction.repeatForever(animation)
        currentAnimation = repeatAnimation
        run(repeatAnimation, withKey: "animation")
    }
    
    func setFlipped(_ flipped: Bool) {
        xScale = flipped ? -1 : 1
    }
    
    func startLayingAnimation() {
        guard !layTextures.isEmpty else { return }
        
        state = .laying
        currentAnimation?.speed = 0
        removeAction(forKey: "animation")
        
        let animation = SKAction.animate(with: layTextures, timePerFrame: 0.1)
        let repeatAnimation = SKAction.repeatForever(animation)
        currentAnimation = repeatAnimation
        run(repeatAnimation, withKey: "animation")
    }
    
    func moveToBasket(basketPosition: CGPoint, completion: @escaping () -> Void) {
        state = .movingToBasket
        
        // 确保在移动过程中播放躺下动画
        startLayingAnimation()
        
        let moveAction = SKAction.move(to: basketPosition, duration: 1.5)
        let fadeAction = SKAction.fadeOut(withDuration: 0.5)
        let sequence = SKAction.sequence([moveAction, fadeAction])
        
        run(sequence) {
            self.state = .inBasket
            completion()
        }
    }
    
    func moveOffScreen(completion: @escaping () -> Void) {
        state = .disappeared
        
        let moveAction = SKAction.moveBy(x: 200, y: 0, duration: 2.0)
        let fadeAction = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([moveAction, fadeAction])
        
        run(group) {
            completion()
        }
    }
}

// MARK: - 自定义GIF播放器
class CustomGIFPlayer {
    // 添加缓存机制
    private static var gifCache: [String: ([SKTexture], TimeInterval)] = [:]
    
    static func loadGIFFrames(from data: Data) -> ([UIImage], TimeInterval) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return ([], 0.0)
        }
        
        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0.0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                // 获取每帧的持续时间
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    
                    var frameDuration: Double = 0.1 // 默认持续时间
                    
                    if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                        frameDuration = delayTime
                    } else if let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                        frameDuration = unclampedDelayTime
                    }
                    
                    // 确保最小帧持续时间
                    if frameDuration < 0.02 {
                        frameDuration = 0.1
                    }
                    
                    totalDuration += frameDuration
                }
            }
        }
        
        return (images, totalDuration)
    }
    
    // 新增缓存版本的加载方法
    static func loadGIFTexturesFromBundle(named fileName: String) -> ([SKTexture], TimeInterval)? {
        // 先检查缓存
        if let cached = gifCache[fileName] {
            print("CustomGIFPlayer: 从缓存加载 \(fileName)")
            return cached
        }
        
        // 缓存中没有，重新加载
        if let (gifImages, totalDuration) = loadGIFFromBundle(named: fileName) {
            let textures = gifImages.map { SKTexture(cgImage: $0.cgImage!) }
            // 存入缓存
            gifCache[fileName] = (textures, totalDuration)
            print("CustomGIFPlayer: 已缓存 \(fileName)，帧数: \(textures.count)")
            return (textures, totalDuration)
        }
        
        return nil
     }
     
     // 清理缓存方法
     static func clearCache() {
         gifCache.removeAll()
         print("CustomGIFPlayer: 缓存已清理")
     }
     
     static func loadGIFFromBundle(named fileName: String) -> ([UIImage], TimeInterval)? {
        print("CustomGIFPlayer: 尝试加载 \(fileName)")
        
        // 首先尝试使用NSDataAsset从Assets.xcassets加载
        if let dataAsset = NSDataAsset(name: fileName) {
            print("CustomGIFPlayer: 通过NSDataAsset找到数据，大小: \(dataAsset.data.count) bytes")
            let (images, duration) = loadGIFFrames(from: dataAsset.data)
            if !images.isEmpty {
                print("CustomGIFPlayer: 成功解析GIF，帧数: \(images.count)")
                return (images, duration)
            }
        } else {
            print("CustomGIFPlayer: NSDataAsset加载失败")
        }
        
        // 尝试从Bundle中直接加载
        if let path = Bundle.main.path(forResource: fileName, ofType: "gif"),
           let data = NSData(contentsOfFile: path) as Data? {
            print("CustomGIFPlayer: 通过Bundle路径找到文件: \(path)")
            let (images, duration) = loadGIFFrames(from: data)
            if !images.isEmpty {
                print("CustomGIFPlayer: 成功解析GIF，帧数: \(images.count)")
                return (images, duration)
            }
        } else {
            print("CustomGIFPlayer: Bundle路径加载失败")
        }
        
        // 如果直接加载失败，尝试从Assets.xcassets中的dataset加载
        if let path = Bundle.main.path(forResource: "run", ofType: "gif", inDirectory: "Assets.xcassets/\(fileName).dataset"),
           let data = NSData(contentsOfFile: path) as Data? {
            print("CustomGIFPlayer: 通过dataset路径找到文件: \(path)")
            let (images, duration) = loadGIFFrames(from: data)
            if !images.isEmpty {
                print("CustomGIFPlayer: 成功解析GIF，帧数: \(images.count)")
                return (images, duration)
            }
        } else {
            print("CustomGIFPlayer: dataset路径加载失败")
        }
        
        print("CustomGIFPlayer: 所有加载方法都失败了")
        return nil
    }
}

struct HandRecoverView: View {
    let level: Int
    @Environment(\.dismiss) private var dismiss
    @State private var gameScene: HandRecoverGameScene?
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            // 摄像头预览层（背景）
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            if let scene = gameScene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .background(Color.clear)
            } else {
                // 加载占位符
                ZStack {
                    Color.green.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("加载游戏场景中...")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                }
            }
            
            // 返回按钮覆盖层
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("home_icon_in_game")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .padding(5)
                            .background(Color.clear)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 5)  // 原来50，向上移动45像素（0.9个图标长度）
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
        .onAppear {
            print("HandRecoverView appeared with level: \(level)")
            setupGameScene()
            cameraManager.startSession()
        }
        .onDisappear {
            gameScene?.removeFromParent()
            gameScene = nil
            cameraManager.stopSession()
        }
    }
    
    private func setupGameScene() {
        let scene = HandRecoverGameScene(level: level, cameraManager: cameraManager)
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .aspectFill
        
        // 设置游戏结束回调
        scene.onGameEnd = {
            DispatchQueue.main.async {
                dismiss()
            }
        }
        
        self.gameScene = scene
    }
}

class HandRecoverGameScene: SKScene {
    private let level: Int
    private let cameraManager: CameraManager
    var onGameEnd: (() -> Void)?
    private var handIcon: SKSpriteNode?
    private var startButton: SKSpriteNode?
    private var basket: SKSpriteNode?
    private var blackboard: SKSpriteNode?
    private var instructionLabel: SKLabelNode?
    private var yesButton: SKSpriteNode?
    private var mascot: SKSpriteNode?
    private var gameStarted = false
    private var countdownLabel: SKLabelNode?
    private var raccoons: [RaccoonSprite] = []
    private var maxRaccoons = 1
    private var raccoonTimer: Timer?
    private var gameTimer: Timer?
    private var currentRaccoon: RaccoonSprite?
    private var isHandClenched = false
    private var clenchStartTime: TimeInterval = 0
    private let clenchDuration: TimeInterval = 1.0 // 握拳1秒后开始移动
    private var canGenerateNewRaccoon = true
    
    // 游戏计时器相关
    private var gameTimerIcon: SKSpriteNode?
    private var gameTimerLabel: SKLabelNode?
    private var gameCountdownTimer: Timer?
    private var gameTimeRemaining: Int = 180 // 180秒倒计时
    
    // 篮子计分相关
    private var basketScoreIcon: SKSpriteNode?
    private var basketScoreLabel: SKLabelNode?
    private var raccoonsCaught: Int = 0 // 抓到的小浣熊数量
    private let targetRaccoons: Int = 10 // 通过游戏需要抓住的小浣熊数量
    
    // ML模型手势检测相关变量已在上方定义
    
    init(level: Int, cameraManager: CameraManager) {
        self.level = level
        self.cameraManager = cameraManager
        super.init(size: .zero)
        
        // 启用ML模型手势检测
        cameraManager.onHandGestureDetected = { [weak self] isClenched in
            self?.handleHandGesture(isClenched: isClenched)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupGameElements()
        setupStartInterface()
    }
    
    private func setupBackground() {
        // 设置背景
        let backgroundTexture = SKTexture(imageNamed: "lawn_background")
        let background = SKSpriteNode(texture: backgroundTexture)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = size
        background.zPosition = -1
        addChild(background)
    }
    
    private func setupGameElements() {
        // 添加篮子（进一步放大，保持原比例）- 游戏开始后显示
        let basketTexture = SKTexture(imageNamed: "basket")
        basket = SKSpriteNode(texture: basketTexture)
        let basketOriginalSize = basketTexture.size()
        let basketScale: CGFloat = 3.0  // 调回到3.0倍缩放
        basket?.size = CGSize(width: basketOriginalSize.width * basketScale, height: basketOriginalSize.height * basketScale)
        basket?.position = CGPoint(x: size.width / 2, y: 160)  // 调整到合适位置
        basket?.zPosition = 5
        basket?.isHidden = true  // 初始隐藏，游戏开始后显示
        
        if let basket = basket {
            addChild(basket)
        }
    }
    
    private func setupStartInterface() {
        // 添加黑板 - 中央略偏上位置，保持原比例并放大
        let blackboardTexture = SKTexture(imageNamed: "blackboard")
        blackboard = SKSpriteNode(texture: blackboardTexture)
        let blackboardOriginalSize = blackboardTexture.size()
        let blackboardScale: CGFloat = 2.0  // 放大以适应屏幕
        blackboard?.size = CGSize(width: blackboardOriginalSize.width * blackboardScale, height: blackboardOriginalSize.height * blackboardScale)
        blackboard?.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        blackboard?.zPosition = 10
        
        if let blackboard = blackboard {
            addChild(blackboard)
        }
        
        // 添加指令文字 - 分为两个文字框，各自居中对齐
         // 第一行文字
         let firstLineLabel = SKLabelNode(text: "缓慢抓住小浣熊移动到小筐里")
         firstLineLabel.fontName = "PingFangSC-Medium"
         firstLineLabel.fontSize = 20
         firstLineLabel.fontColor = .white
         firstLineLabel.horizontalAlignmentMode = .center
         firstLineLabel.verticalAlignmentMode = .center
         firstLineLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 95)
         firstLineLabel.zPosition = 11
         
         // 第二行文字
         let secondLineLabel = SKLabelNode(text: "缓慢松开算作成功")
         secondLineLabel.fontName = "PingFangSC-Medium"
         secondLineLabel.fontSize = 20
         secondLineLabel.fontColor = .white
         secondLineLabel.horizontalAlignmentMode = .center
         secondLineLabel.verticalAlignmentMode = .center
         secondLineLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 65)
         secondLineLabel.zPosition = 11
        
        // 保留原有的instructionLabel引用指向第一行
        instructionLabel = firstLineLabel
        
        if let instructionLabel = instructionLabel {
            addChild(instructionLabel)
        }
        
        // 添加第二行文字到场景
        addChild(secondLineLabel)
        
        // 添加确认按钮 - 黑板正下方，下移40像素，保持原比例并放大
        let yesButtonTexture = SKTexture(imageNamed: "yes_button")
        yesButton = SKSpriteNode(texture: yesButtonTexture)
        let yesButtonOriginalSize = yesButtonTexture.size()
        let yesButtonScale: CGFloat = 1.5  // 放大按钮
        yesButton?.size = CGSize(width: yesButtonOriginalSize.width * yesButtonScale, height: yesButtonOriginalSize.height * yesButtonScale)
        yesButton?.position = CGPoint(x: size.width / 2, y: size.height / 2 - 90)  // 原来-50，下移40像素变为-90
        yesButton?.zPosition = 10
        
        if let yesButton = yesButton {
            addChild(yesButton)
        }
        
        // 添加吉祥物 - 黑板左下角，微微遮盖黑板下沿，水平翻转，保持原比例并放大
        let mascotTexture = SKTexture(imageNamed: "mascot2d")
        mascot = SKSpriteNode(texture: mascotTexture)
        let mascotOriginalSize = mascotTexture.size()
        let mascotScale: CGFloat = 1.2  // 放大吉祥物
        mascot?.size = CGSize(width: mascotOriginalSize.width * mascotScale, height: mascotOriginalSize.height * mascotScale)
        mascot?.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2 + 10)  // 左下角位置，上部微微遮盖黑板
        mascot?.zPosition = 12  // 在黑板图层上方
        mascot?.xScale = -1  // 水平翻转吉祥物
        
        if let mascot = mascot {
            addChild(mascot)
        }
    }
    
    private func startGame() {
        gameStarted = true
        
        // 隐藏开始界面元素
        blackboard?.isHidden = true
        instructionLabel?.isHidden = true
        yesButton?.isHidden = true
        mascot?.isHidden = true
        
        // 隐藏第二行文字
        children.compactMap { $0 as? SKLabelNode }.forEach { label in
            if label.text == "缓慢松开算作成功" {
                label.isHidden = true
            }
        }
        
        // 显示游戏元素
        basket?.isHidden = false
        
        // 设置篮子计分显示
        setupBasketScore()
        
        print("游戏开始 - 关卡 \(level)")
        
        // 开始倒计时
        startCountdown()
    }
    
    // MARK: - 倒计时相关方法
    private func startCountdown() {
        // 创建倒计时标签
        countdownLabel = SKLabelNode(text: "3")
        countdownLabel?.fontName = "AlimamaDongFangDaKai-Regular" // 阿里妈妈东方大楷
        countdownLabel?.fontSize = 80
        countdownLabel?.fontColor = .white // 白色字体
        countdownLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        countdownLabel?.zPosition = 100
        
        if let countdownLabel = countdownLabel {
            addChild(countdownLabel)
        }
        
        var count = 3
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if count > 1 {
                count -= 1
                self.countdownLabel?.text = "\(count)"
            } else {
                // 倒计时结束，直接开始游戏（去掉"开始!"）
                timer.invalidate()
                self.countdownLabel?.removeFromParent()
                self.startRaccoonGame()
            }
        }
    }
    
    // MARK: - 小浣熊游戏逻辑
    private func startRaccoonGame() {
        print("开始小浣熊游戏，关卡: \(level)")
        
        // 设置游戏计时器UI
        setupGameTimer()
        
        // 立即生成第一只小浣熊
        generateRaccoon()
        
        // 设置定时器检查是否需要生成新小浣熊
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.canGenerateNewRaccoon && self.currentRaccoon == nil {
                self.generateRaccoon()
            }
        }
        
        // 开始游戏倒计时
        startGameCountdown()
    }
    
    // MARK: - 游戏计时器相关方法
    private func setupGameTimer() {
        // 添加计时器图标 - 放大一倍
        let timerTexture = SKTexture(imageNamed: "timer")
        gameTimerIcon = SKSpriteNode(texture: timerTexture)
        // 获取原始尺寸并放大一倍
        let originalSize = timerTexture.size()
        gameTimerIcon?.size = CGSize(width: originalSize.width * 2, height: originalSize.height * 2)
        gameTimerIcon?.position = CGPoint(x: size.width / 2 - 40, y: size.height - 180) // 向左移动10像素
        gameTimerIcon?.zPosition = 100
        
        if let gameTimerIcon = gameTimerIcon {
            addChild(gameTimerIcon)
        }
        
        // 添加计时器数字 - 放大一倍
        gameTimerLabel = SKLabelNode(text: "\(gameTimeRemaining)")
        gameTimerLabel?.fontName = "PingFangSC-Bold"
        gameTimerLabel?.fontSize = 64  // 放大一倍：32 * 2 = 64
        gameTimerLabel?.fontColor = UIColor(red: 0x4b/255.0, green: 0x62/255.0, blue: 0x28/255.0, alpha: 1.0) // #4b6228
        gameTimerLabel?.verticalAlignmentMode = .center
        gameTimerLabel?.position = CGPoint(x: size.width / 2 + 30, y: size.height - 180) // 向右移动10像素，调整Y坐标对齐
        gameTimerLabel?.zPosition = 100
        
        if let gameTimerLabel = gameTimerLabel {
            addChild(gameTimerLabel)
        }
    }
    
    private func startGameCountdown() {
        gameCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.gameTimeRemaining -= 1
            self.gameTimerLabel?.text = "\(self.gameTimeRemaining)"
            
            if self.gameTimeRemaining <= 0 {
                timer.invalidate()
                self.endGame()
            }
        }
    }
    
    private func endGame() {
        print("游戏时间结束")
        
        // 停止所有计时器
        gameTimer?.invalidate()
        gameCountdownTimer?.invalidate()
        raccoonTimer?.invalidate()
        
        // 移除当前小浣熊
        currentRaccoon?.removeFromParent()
        currentRaccoon = nil
        
        // 隐藏游戏计时器UI
        gameTimerIcon?.removeFromParent()
        gameTimerLabel?.removeFromParent()
        
        // 隐藏篮子计分UI
        basketScoreIcon?.removeFromParent()
        basketScoreLabel?.removeFromParent()
        
        // 检查是否达到通关条件
        if raccoonsCaught >= targetRaccoons {
            print("游戏通过！抓到了\(raccoonsCaught)只小浣熊")
            // 记录训练成绩并上传打卡数据
            recordTrainingSuccess()
        }
        
        // 调用游戏结束回调
        onGameEnd?()
    }
    
    private func endGameWithSuccess() {
        print("游戏成功通过！")
        
        // 停止所有计时器
        gameTimer?.invalidate()
        gameCountdownTimer?.invalidate()
        raccoonTimer?.invalidate()
        
        // 移除当前小浣熊
        currentRaccoon?.removeFromParent()
        currentRaccoon = nil
        
        // 隐藏游戏计时器UI
        gameTimerIcon?.removeFromParent()
        gameTimerLabel?.removeFromParent()
        
        // 隐藏篮子计分UI
        basketScoreIcon?.removeFromParent()
        basketScoreLabel?.removeFromParent()
        
        // 记录训练成绩并上传打卡数据
        recordTrainingSuccess()
        
        // 调用游戏结束回调
        onGameEnd?()
    }
    
    private func recordTrainingSuccess() {
        let networkService = NetworkService.shared
        let gameTime = 180 - gameTimeRemaining // 实际游戏时间
        
        // 记录训练成绩
        networkService.recordTraining(
            trainingType: "hand",
            level: level,
            score: raccoonsCaught,
            duration: gameTime,
            data: ["raccoonsCaught": raccoonsCaught, "targetRaccoons": targetRaccoons]
        ) { result in
            switch result {
            case .success:
                print("训练成绩记录成功")
                // 训练成绩记录成功后，先解锁下一关，再执行签到
                self.unlockNextLevel()
                self.performSignIn()
            case .failure(let error):
                print("训练成绩记录失败: \(error)")
                // 即使记录失败，也要尝试签到和解锁下一关
                self.performSignIn()
            }
        }
    }
    
    private func performSignIn() {
        let networkService = NetworkService.shared
        
        // 执行签到
        networkService.signIn { result in
            switch result {
            case .success(let response):
                print("签到成功: \(response)")
            case .failure(let error):
                print("签到失败: \(error)")
            }
        }
    }
    
    private func unlockNextLevel() {
        let networkService = NetworkService.shared
        let nextLevel = level + 1
        
        // 先记录下一关的成绩（分数为0）来更新 max_level_reached
        // 这样可以确保下一关被解锁
        networkService.recordTraining(
            trainingType: "hand",
            level: nextLevel,
            score: 0, // 使用0分来解锁关卡
            duration: 0,
            data: ["unlock": true]
        ) { recordResult in
            switch recordResult {
            case .success:
                print("成功解锁关卡 \(nextLevel)，现在更新当前关卡")
                // 解锁成功后，更新当前关卡
                networkService.updateCurrentLevel(
                    trainingType: "hand",
                    level: nextLevel
                ) { updateResult in
                    switch updateResult {
                    case .success:
                        print("成功设置当前关卡为: \(nextLevel)")
                    case .failure(let updateError):
                        print("设置当前关卡失败: \(updateError)")
                    }
                }
            case .failure(let recordError):
                print("解锁关卡失败: \(recordError)")
            }
        }
    }
    
    // MARK: - 篮子计分相关方法
    private func setupBasketScore() {
        guard let basket = basket else { return }
        
        // 添加手势图标
        let handTexture = SKTexture(imageNamed: "hand_cartoon_avatar")
        basketScoreIcon = SKSpriteNode(texture: handTexture)
        basketScoreIcon?.size = CGSize(width: 90, height: 90)  // 放大三倍：30 * 3 = 90
        basketScoreIcon?.position = CGPoint(x: basket.position.x - 75, y: basket.position.y + 10)  // 向下移动10像素，向中心移动5像素
        basketScoreIcon?.zPosition = 100
        
        if let basketScoreIcon = basketScoreIcon {
            addChild(basketScoreIcon)
        }
        
        // 添加计分数字
        basketScoreLabel = SKLabelNode(text: "\(raccoonsCaught)")
        basketScoreLabel?.fontName = "PingFangSC-Bold"
        basketScoreLabel?.fontSize = 84  // 放大三倍：28 * 3 = 84
        basketScoreLabel?.fontColor = .white
        basketScoreLabel?.verticalAlignmentMode = .center  // 设置垂直对齐为中心
        basketScoreLabel?.position = CGPoint(x: basket.position.x + 65, y: basket.position.y + 10)  // 向下移动10像素，向中心移动5像素
        basketScoreLabel?.zPosition = 100
        
        if let basketScoreLabel = basketScoreLabel {
            addChild(basketScoreLabel)
        }
    }
    
    private func updateBasketScore() {
        basketScoreLabel?.text = "\(raccoonsCaught)"
    }
    
    private func generateRaccoon() {
        // 检查是否可以生成新小浣熊
        guard canGenerateNewRaccoon && currentRaccoon == nil else {
            print("无法生成新小浣熊：canGenerate=\(canGenerateNewRaccoon), currentRaccoon=\(currentRaccoon != nil)")
            return
        }
        
        print("开始生成小浣熊")
        
        let raccoon = RaccoonSprite()
        
        // 从屏幕中间随机位置出现
        let startPosition = CGPoint(
            x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
            y: CGFloat.random(in: size.height * 0.3...size.height * 0.7)
        )
        
        // 随机选择移动方向（6个方向，去掉上下）
         let directions: [(x: CGFloat, y: CGFloat)] = [
             (-1, 0),   // 左
             (1, 0),    // 右
             (-1, -1),  // 左下
             (1, -1),   // 右下
             (-1, 1),   // 左上
             (1, 1)     // 右上
         ]
         
         let randomDirection = directions.randomElement()!
         
         // 固定移动时间
         let fixedDuration: TimeInterval = 4.0
         
         // 计算从当前位置到屏幕边缘的实际距离
         var distanceToEdge: CGFloat = 0
         
         switch randomDirection {
         case (-1, 0): // 向左
             distanceToEdge = startPosition.x + 50 // 到左边缘的距离
         case (1, 0): // 向右
             distanceToEdge = size.width - startPosition.x + 50 // 到右边缘的距离
         case (-1, -1): // 左下
             let leftDist = startPosition.x + 50
             let downDist = startPosition.y + 50
             distanceToEdge = min(leftDist, downDist) / cos(.pi / 4) // 对角线距离
         case (1, -1): // 右下
             let rightDist = size.width - startPosition.x + 50
             let downDist = startPosition.y + 50
             distanceToEdge = min(rightDist, downDist) / cos(.pi / 4)
         case (-1, 1): // 左上
             let leftDist = startPosition.x + 50
             let upDist = size.height - startPosition.y + 50
             distanceToEdge = min(leftDist, upDist) / cos(.pi / 4)
         case (1, 1): // 右上
             let rightDist = size.width - startPosition.x + 50
             let upDist = size.height - startPosition.y + 50
             distanceToEdge = min(rightDist, upDist) / cos(.pi / 4)
         default:
             distanceToEdge = 200 // 默认值
         }
         
         // 根据固定时间和实际距离计算移动距离（确保不超出屏幕）
         let maxMoveDistance = distanceToEdge * 0.8 // 使用80%的距离，确保不会立即跑出屏幕
         let moveDistance = min(maxMoveDistance, distanceToEdge)
         
         let endPosition = CGPoint(
             x: startPosition.x + randomDirection.x * moveDistance,
             y: startPosition.y + randomDirection.y * moveDistance
         )
        
        raccoon.position = startPosition
        raccoon.zPosition = 10
        
        // 根据移动方向设置翻转：向右移动时翻转动画
        let shouldFlip = randomDirection.x > 0 // 向右移动时翻转
        raccoon.setFlipped(shouldFlip)
        
        addChild(raccoon)
        currentRaccoon = raccoon
        canGenerateNewRaccoon = false
        
        // 移动小浣熊到目标位置
        let moveAction = SKAction.move(to: endPosition, duration: fixedDuration)
        raccoon.run(moveAction) {
            // 小浣熊跑出屏幕
            self.handleRaccoonOffScreen()
        }
        
        print("✅ 小浣熊生成成功，从中间位置出现，方向: (\(randomDirection.x), \(randomDirection.y))")
    }
    
    private func handleRaccoonOffScreen() {
        currentRaccoon?.removeFromParent()
        currentRaccoon = nil
        canGenerateNewRaccoon = true
        print("小浣熊跑出屏幕，可以生成新的小浣熊")
    }
    
    private func handleHandGesture(isClenched: Bool) {
         guard let raccoon = currentRaccoon else { return }
         
         if isClenched && !isHandClenched {
             // 开始握拳
             isHandClenched = true
             clenchStartTime = CACurrentMediaTime()
             print("开始握拳")
             
             // 立即切换到躺下动画
             raccoon.startLayingAnimation()
             
         } else if !isClenched && isHandClenched {
             // 松开手
             isHandClenched = false
             let clenchDuration = CACurrentMediaTime() - clenchStartTime
             
             if clenchDuration >= self.clenchDuration {
                 // 握拳时间足够，小浣熊移动到篮子
                 print("握拳时间足够(\(clenchDuration)s)，小浣熊移动到篮子")
                 
                 raccoon.removeAllActions()
                 
                 if let basketPosition = basket?.position {
                     raccoon.moveToBasket(basketPosition: basketPosition) {
                         self.handleRaccoonCaught()
                     }
                 }
             } else {
                 print("握拳时间不够(\(clenchDuration)s < \(self.clenchDuration)s)，恢复跑步")
                 // 恢复跑步动画
                 raccoon.startRunningAnimation()
             }
                          
             // 如果小浣熊已经被抓住（currentRaccoon为nil），允许生成新的小浣熊
             if currentRaccoon == nil {
                 canGenerateNewRaccoon = true
                 print("松开手势，允许生成新小浣熊")
             }
         } else if isClenched && isHandClenched {
             // 持续握拳状态
             let currentClenchDuration = CACurrentMediaTime() - clenchStartTime
             if currentClenchDuration >= self.clenchDuration {
                 // 握拳时间足够，开始移动到篮子
                 if raccoon.state == .laying {
                     print("持续握拳，开始移动小浣熊到篮子")
                     raccoon.removeAllActions()
                     
                     if let basketPosition = basket?.position {
                         raccoon.moveToBasket(basketPosition: basketPosition) {
                             self.handleRaccoonCaught()
                         }
                     }
                 }
             }
         }
     }
    
    private func handleRaccoonCaught() {
        currentRaccoon = nil
        canGenerateNewRaccoon = false  // 不立即允许生成新的，等待松开手势
        raccoonsCaught += 1
        updateBasketScore()
        print("小浣熊被成功抓住！当前数量: \(raccoonsCaught)/\(targetRaccoons)，等待松开手势")
    }
    
    // 移除旧的小浣熊管理方法，现在使用RaccoonSprite类管理
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if !gameStarted {
            // 检查是否点击了确认按钮
            if let yesButton = yesButton, yesButton.contains(location) {
                startGame()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 现在使用ML模型检测握拳，不需要触摸事件处理
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 现在使用ML模型检测握拳，不需要触摸事件处理
    }
    
    deinit {
        // 清理定时器
        raccoonTimer?.invalidate()
        gameTimer?.invalidate()
        gameCountdownTimer?.invalidate()
        
        // 清理GIF缓存
        CustomGIFPlayer.clearCache()
        
        // 清理当前小浣熊
        currentRaccoon?.removeFromParent()
        currentRaccoon = nil
        
        // 清理小浣熊数组
        raccoons.removeAll()
        
        print("HandRecoverGameScene 已销毁")
    }
}



#Preview {
    HandRecoverView(level: 1)
}
