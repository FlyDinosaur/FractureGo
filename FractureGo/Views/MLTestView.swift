import SwiftUI
import Combine
import PhotosUI

struct MLTestView: View {
    @StateObject private var viewModel = MLTestViewModel()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 服务状态
                    serviceStatusSection
                    
                    // 图片选择
                    imageSelectionSection
                    
                    // 检测按钮
                    detectionButtonsSection
                    
                    // 结果显示
                    resultsSection
                }
                .padding()
            }
            .navigationTitle("ML服务测试")
            .onAppear {
                viewModel.initializeServices()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private var serviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("服务状态")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(viewModel.isPoseServiceInitialized ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text("姿势检测服务")
                Spacer()
                Text(viewModel.isPoseServiceInitialized ? "已初始化" : "未初始化")
                    .foregroundColor(viewModel.isPoseServiceInitialized ? .green : .red)
            }
            
            HStack {
                Circle()
                    .fill(viewModel.isHandServiceInitialized ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text("手部检测服务")
                Spacer()
                Text(viewModel.isHandServiceInitialized ? "已初始化" : "未初始化")
                    .foregroundColor(viewModel.isHandServiceInitialized ? .green : .red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var imageSelectionSection: some View {
        VStack(spacing: 10) {
            Text("选择图片")
                .font(.headline)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(10)
                    .overlay(
                        Text("点击选择图片")
                            .foregroundColor(.gray)
                    )
            }
            
            Button("选择图片") {
                showingImagePicker = true
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var detectionButtonsSection: some View {
        VStack(spacing: 10) {
            Text("检测功能")
                .font(.headline)
            
            HStack(spacing: 20) {
                Button("姿势检测") {
                    if let image = selectedImage {
                        viewModel.detectPose(in: image)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedImage == nil || !viewModel.isPoseServiceInitialized)
                
                Button("手部检测") {
                    if let image = selectedImage {
                        viewModel.detectHands(in: image)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedImage == nil || !viewModel.isHandServiceInitialized)
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("检测结果")
                .font(.headline)
            
            if viewModel.isLoading {
                ProgressView("检测中...")
                    .frame(maxWidth: .infinity)
            }
            
            if let error = viewModel.errorMessage {
                Text("错误: \(error)")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if let result = viewModel.poseResult {
                VStack(alignment: .leading, spacing: 5) {
                    Text("姿势检测结果:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("关键点数量: \(result.landmarks.count)")
                    Text("置信度: \(String(format: "%.2f", result.confidence))")
                    Text("可见性: \(result.isVisible ? "是" : "否")")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            if let result = viewModel.handResult {
                VStack(alignment: .leading, spacing: 5) {
                    Text("手部检测结果:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let leftHand = result.leftHand {
                        Text("左手: \(leftHand.landmarks.count)个关键点, 置信度: \(String(format: "%.2f", leftHand.confidence))")
                    }
                    
                    if let rightHand = result.rightHand {
                        Text("右手: \(rightHand.landmarks.count)个关键点, 置信度: \(String(format: "%.2f", rightHand.confidence))")
                    }
                    
                    if result.leftHand == nil && result.rightHand == nil {
                        Text("未检测到手部")
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - ViewModel
class MLTestViewModel: ObservableObject {
    @Published var isPoseServiceInitialized = false
    @Published var isHandServiceInitialized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var poseResult: PoseDetectionResult?
    @Published var handResult: HandDetectionResult?
    
    private var cancellables = Set<AnyCancellable>()
    private let serviceManager = MLServiceManager.shared
    
    func initializeServices() {
        isLoading = true
        errorMessage = nil
        
        serviceManager.initializeAllServices()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.isPoseServiceInitialized = self?.serviceManager.poseDetectionService.isInitialized ?? false
                        self?.isHandServiceInitialized = self?.serviceManager.handDetectionService.isInitialized ?? false
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func detectPose(in image: UIImage) {
        isLoading = true
        errorMessage = nil
        poseResult = nil
        
        serviceManager.poseDetectionService.detectPose(in: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] result in
                    self?.poseResult = result
                }
            )
            .store(in: &cancellables)
    }
    
    func detectHands(in image: UIImage) {
        isLoading = true
        errorMessage = nil
        handResult = nil
        
        serviceManager.handDetectionService.detectHands(in: image)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] result in
                    self?.handResult = result
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    MLTestView()
}