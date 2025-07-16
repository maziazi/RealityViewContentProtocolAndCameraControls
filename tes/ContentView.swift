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
    @State private var ballEntity: ModelEntity?  // Tambahan untuk track bola
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
            RealityView { content in
                setupScene(content: content)
                loadBallModel(content: content)
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
                
                // Reset Button
                HStack(spacing: 20) {
                    Button("Reset Ball Position") {
                        resetBallPosition()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
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
        
        // Ground plane (optional)
        let groundMesh = MeshResource.generatePlane(width: 3, depth: 3)
        let groundMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.3), isMetallic: false)
        let ground = ModelEntity(mesh: groundMesh, materials: [groundMaterial])
        ground.position = [0, -0.5, 0]
        content.add(ground)
    }
    
    private func loadBallModel(content: any RealityViewContentProtocol) {
        if let modelURL = Bundle.main.url(forResource: "ball", withExtension: "usdz") {
            Task {
                do {
                    let entity = try await ModelEntity(contentsOf: modelURL)
                    
                    // Posisi awal bola (di atas slide)
                    entity.position = [0, 1, 0]  // Posisi awal yang lebih tinggi
                    entity.scale = [0.07, 0.07, 0.07]
                    
                    await MainActor.run {
                        content.add(entity)
                        self.ballEntity = entity  // Simpan reference ke bola
                    }
                } catch {
                    print("Failed to load ball: \(error)")
                    // Fallback: create simple ball if loading fails
                    await MainActor.run {
                        self.createFallbackBall(content: content)
                    }
                }
            }
        } else {
            // Create fallback ball if file not found
            createFallbackBall(content: content)
        }
    }
    
    private func createFallbackBall(content: any RealityViewContentProtocol) {
        // Buat bola sederhana jika file tidak ditemukan
        let ballMesh = MeshResource.generateSphere(radius: 0.1)
        let ballMaterial = SimpleMaterial(color: .systemRed, isMetallic: false)
        let ball = ModelEntity(mesh: ballMesh, materials: [ballMaterial])
        
        ball.position = [0, 0.7, 0]  // Posisi awal
        ball.scale = [0.07, 0.07, 0.07]
        
        content.add(ball)
        self.ballEntity = ball
    }
    
    private func loadUSDZModel(content: any RealityViewContentProtocol) {
        // Method 1: Loading dari Bundle
        if let modelURL = Bundle.main.url(forResource: "Slide_Rumit_Tinggi", withExtension: "usdz") {
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
                entity.position = [0, -0.4, 0]  // Posisi slide sedikit di bawah
                entity.scale = [0.07, 0.07, 0.07]  // Scale yang lebih reasonable
//                anchor.addChild(entity)

                                
                await applyStaticMeshCollision(to: entity)

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
        // Membuat slide fallback sederhana
        let mesh = MeshResource.generateBox(size: [1.5, 0.1, 2])
        let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Rotate untuk membuat slope
        entity.position = [0, 0, 0]
        entity.orientation = simd_quatf(angle: -0.2, axis: [1, 0, 0])  // Slight slope
        
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
    
    // MARK: - Ball Control Methods
    
    private func resetBallPosition() {
        guard let ball = ballEntity else {
            print("⚠️ Ball entity not found!")
            return
        }
        
        // Reset bola ke posisi awal (di atas slide)
        ball.position = [0, 0.7, 0]  // Posisi awal
        ball.orientation = simd_quatf(angle: 0, axis: [0, 0.7, 0])  // Reset rotasi
        
        print("✅ Ball reset to initial position: [0, 0,7, 0]")
    }
    
    @MainActor
    // Fungsi untuk menerapkan static mesh collision
    func applyStaticMeshCollision(to entity: Entity) async {
        for child in entity.children {
            if let model = child as? ModelEntity,
               let modelComponent = model.components[ModelComponent.self] {
                
                let mesh = modelComponent.mesh
                
                // Menambahkan task untuk async call
                do {
                    let collision = try await CollisionComponent(shapes: [.generateStaticMesh(from: mesh)])
                    model.components[CollisionComponent.self] = collision
                    print("✅ Static mesh collision diterapkan pada: \(model.name)")
                } catch {
                    print("⚠️ Gagal generate static mesh untuk \(model.name): \(error)")
                    
                    // Fallback ke convex hull
                    do {
                        let shape = try await ShapeResource.generateConvex(from: mesh)
                        model.components.set(CollisionComponent(shapes: [shape]))
                        print("📦 Convex collision fallback diterapkan pada: \(model.name)")
                    } catch {
                        print("⚠️ Gagal generate convex untuk \(model.name): \(error)")
                        
                        // Fallback terakhir ke bounding box
                        let bounds = model.visualBounds(relativeTo: nil)
                        let size = bounds.max - bounds.min
                        let boxShape = ShapeResource.generateBox(size: size)
                        model.components.set(CollisionComponent(shapes: [boxShape]))
                        print("📦 Box collision fallback diterapkan pada: \(model.name)")
                    }
                }

                let trackMaterial = PhysicsMaterialResource.generate(
                    friction: 800.0,      // lintasan tidak licin
                    restitution: 0.0
                )

                model.components.set(PhysicsBodyComponent(
                    massProperties: .default,
                    material: trackMaterial,
                    mode: .static
                ))
            }
            // Recursively apply collision to children
            await applyStaticMeshCollision(to: child)
        }
    }

    // MARK: - Camera Controls
    
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
    
    // MARK: - Action Methods (existing)
    
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
