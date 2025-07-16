//
//  ContentView.swift
//  tes
//
//  Created by Muhamad Azis on 16/07/25.
//

import SwiftUI
import RealityKit

struct USDZRealityViewDemo: View {
    @State private var modelEntity: ModelEntity?
    @State private var isLoaded = false
    @State private var loadingError: String?
    @State private var rotationSpeed: Float = 1.0
    @State private var cameraMode: CameraMode = .orbit
    
    enum CameraMode: String, CaseIterable {
        case dolly = "Dolly"
        case orbit = "Orbit"
        case pan = "Pan"
        case tilt = "Tilt"
        case none = "None"
    }
    
    var body: some View {
        VStack {
            // Header Controls
            HStack {
                Text("USDZ Model Viewer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isLoaded {
                    Text("✅ Loaded")
                        .foregroundColor(.green)
                } else if loadingError != nil {
                    Text("❌ Error")
                        .foregroundColor(.red)
                } else {
                    Text("⏳ Loading...")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            
            // Main RealityView menggunakan RealityViewContentProtocol
            RealityView { content in
                setupScene(content: content)
                loadUSDZModel(content: content)
            } update: { content in
                updateModel(content: content)
            }
            .realityViewCameraControls(getCameraControl())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Controls
            VStack(spacing: 16) {
                // Camera Mode Selector
                HStack {
                    Text("Camera Mode:")
                        .font(.headline)
                    
                    Picker("Camera Mode", selection: $cameraMode) {
                        ForEach(CameraMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Rotation Speed Control
                HStack {
                    Text("Rotation Speed:")
                        .font(.headline)
                    
                    Slider(value: $rotationSpeed, in: 0...3, step: 0.1) {
                        Text("Speed")
                    }
                    .frame(maxWidth: 200)
                    
                    Text("\(rotationSpeed, specifier: "%.1f")")
                        .font(.caption)
                        .frame(width: 30)
                }
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button("Reset Position") {
                        resetModelPosition()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reload Model") {
                        reloadModel()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            // Error Message
            if let error = loadingError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()
            }
        }
    }
    
    // MARK: - RealityView Setup menggunakan RealityViewContentProtocol
    
    private func setupScene(content: any RealityViewContentProtocol) {
        // Add lighting untuk scene yang lebih baik
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 1000
        directionalLight.light.color = .white
        directionalLight.position = [2, 2, 2]
        directionalLight.look(at: [0, 0, 0], from: directionalLight.position, relativeTo: nil)
        content.add(directionalLight)
        
//        // Ambient light untuk pencahayaan yang lebih merata
//        let ambientLight = AmbientLight()
//        ambientLight.light.intensity = 300
//        ambientLight.light.color = .white
//        content.add(ambientLight)
        
        // Ground plane (optional)
        let groundMesh = MeshResource.generatePlane(width: 3, depth: 3)
        let groundMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.3), isMetallic: false)
        let ground = ModelEntity(mesh: groundMesh, materials: [groundMaterial])
        ground.position = [0, -0.5, 0]
        content.add(ground)
    }
    
    private func loadUSDZModel(content: any RealityViewContentProtocol) {
        // Contoh loading USDZ model
        // Ganti "your_model.usdz" dengan nama file USDZ Anda
        
        // Method 1: Loading dari Bundle
        if let modelURL = Bundle.main.url(forResource: "Kursi", withExtension: "usdz") {
            loadModelFromURL(url: modelURL, content: content)
        } else {
            // Method 2: Membuat model sederhana jika USDZ tidak tersedia
            createFallbackModel(content: content)
        }
    }
    
    private func loadModelFromURL(url: URL, content: any RealityViewContentProtocol) {
        Task {
            do {
                let entity = try await ModelEntity(contentsOf: url)
                
                // Set posisi dan skala
                entity.position = [0, 0, 0]
                entity.scale = [1, 1, 1]
                
                // Add ke scene
                await MainActor.run {
                    content.add(entity)
                    self.modelEntity = entity
                    self.isLoaded = true
                    self.loadingError = nil
                }
                
            } catch {
                await MainActor.run {
                    self.loadingError = "Failed to load USDZ: \(error.localizedDescription)"
                    self.createFallbackModel(content: content)
                }
            }
        }
    }
    
    private func createFallbackModel(content: any RealityViewContentProtocol) {
        // Membuat model fallback sederhana
        let mesh = MeshResource.generateBox(size: 0.3)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        entity.position = [0, 0, 0]
        content.add(entity)
        
        self.modelEntity = entity
        self.isLoaded = true
        self.loadingError = nil
    }
    
    private func updateModel(content: any RealityViewContentProtocol) {
        guard let entity = modelEntity else { return }
        
        // Update rotasi berdasarkan speed
        if rotationSpeed > 0 {
            let currentTime = Date().timeIntervalSince1970
            let rotationAngle = Float(currentTime) * rotationSpeed
            entity.orientation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        }
    }
    
    // MARK: - Camera Controls menggunakan RealityViewCameraContent
    
    private func getCameraControl() -> CameraControls {
        switch cameraMode {
        case .dolly:
            return .dolly
        case .orbit:
            return .orbit
        case .pan:
            return .pan
        case .tilt:
            return .tilt
        case .none:
            return .none
        }
    }
    
    // MARK: - Action Methods
    
    private func resetModelPosition() {
        guard let entity = modelEntity else { return }
        entity.position = [0, 0, 0]
        entity.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
    }
    
    private func reloadModel() {
        isLoaded = false
        loadingError = nil
        modelEntity?.removeFromParent()
        modelEntity = nil
        
        // Reload akan terjadi otomatis karena RealityView update
    }
}

// MARK: - Preview

struct ContentView: View {
    var body: some View {
        USDZRealityViewDemo()
    }
}

#Preview {
    ContentView()
}
