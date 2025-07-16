# RealityView dan Camera Controls

## 📋 Daftar Isi
- [Pengenalan RealityView](#pengenalan-realityview)
- [RealityViewContentProtocol](#realityviewcontentprotocol)
- [Camera Controls](#camera-controls)
- [Implementasi USDZ](#implementasi-usdz)
- [Contoh Kode](#contoh-kode)
- [Tips dan Best Practices](#tips-dan-best-practices)

## 🌟 Pengenalan RealityView

**RealityView** adalah komponen SwiftUI yang memungkinkan Anda menampilkan konten 3D dan AR dalam aplikasi iOS. RealityView menjembatani antara SwiftUI dan RealityKit, memungkinkan integrasi seamless antara UI 2D dan konten 3D.

### Fitur Utama:
- ✅ Menampilkan model 3D (USDZ, OBJ, dll)
- ✅ Integrasi dengan SwiftUI
- ✅ Kontrol kamera yang fleksibel
- ✅ Animasi dan interaksi real-time
- ✅ Support AR dan VR

## 📦 RealityViewContentProtocol

`RealityViewContentProtocol` adalah protokol yang mendefinisikan bagaimana konten 3D dikelola dalam RealityView. Protokol ini menyediakan interface untuk menambah, menghapus, dan memanipulasi entity 3D.

### Dokumentasi Resmi
🔗 [Apple Documentation - RealityViewContentProtocol](https://developer.apple.com/documentation/realitykit/realityviewcontentprotocol)

### Fungsi Utama:

#### `add(_:)`
Menambahkan entity 3D ke dalam scene
```swift
content.add(modelEntity)
```

#### `remove(_:)`
Menghapus entity dari scene
```swift
content.remove(modelEntity)
```

#### Properties
- Mengelola hierarki entity
- Mengatur transformasi objek
- Menangani collision dan physics

### Contoh Penggunaan Dasar:
```swift
RealityView { content in
    // Setup scene
    let entity = ModelEntity(mesh: .generateBox(size: 0.3))
    content.add(entity)
} update: { content in
    // Update logic
}
```

## 🎥 Camera Controls

Camera controls menentukan bagaimana user dapat berinteraksi dengan kamera dalam scene 3D. Setiap mode memberikan pengalaman navigasi yang berbeda.

### Dokumentasi Resmi
🔗 [Apple Documentation - realityViewCameraControls](https://developer.apple.com/documentation/swiftui/view/realityviewcameracontrols(_:))

### 5 Mode Camera Controls:

#### 1. **🔄 Orbit**
- **Fungsi:** Kamera berputar mengelilingi objek dengan titik pusat tetap
- **Gesture:** 
  - Drag = rotate around object
  - Pinch = zoom in/out
- **Use Case:** Product showcase, 3D model inspection
- **Cocok untuk:** Memeriksa detail objek dari segala sudut

```swift
.realityViewCameraControls(.orbit)
```

#### 2. **🎬 Dolly**
- **Fungsi:** Kamera bergerak maju-mundur sepanjang axis view
- **Gesture:** 
  - Pinch = move closer/farther
  - Drag = slight pan/tilt
- **Use Case:** Cinematic effects, dramatic zoom
- **Cocok untuk:** Efek sinematik dan presentasi dramatis

```swift
.realityViewCameraControls(.dolly)
```

#### 3. **↔️ Pan**
- **Fungsi:** Kamera bergerak horizontal/vertikal tanpa mengubah jarak
- **Gesture:** 
  - Drag horizontal = pan left/right
  - Drag vertical = pan up/down
- **Use Case:** Large environments, architectural walkthroughs
- **Cocok untuk:** Menjelajahi environment yang luas

```swift
.realityViewCameraControls(.pan)
```

#### 4. **↕️ Tilt**
- **Fungsi:** Kamera rotate pada axis horizontal (pitch)
- **Gesture:** 
  - Drag vertical = tilt up/down
  - Drag horizontal = minimal effect
- **Use Case:** Looking at tall objects, examining details
- **Cocok untuk:** Melihat objek tinggi atau detail vertikal

```swift
.realityViewCameraControls(.tilt)
```

#### 5. **🚫 None**
- **Fungsi:** Tidak ada kontrol kamera
- **Gesture:** No response
- **Use Case:** Tutorials, guided tours, fixed presentations
- **Cocok untuk:** Presentasi statis dan tutorial terpandu

```swift
.realityViewCameraControls(.none)
```

## 📄 Implementasi USDZ

USDZ (Universal Scene Description) adalah format file 3D yang dikembangkan oleh Apple untuk AR dan 3D content.

### Loading USDZ dari Bundle:
```swift
private func loadUSDZModel(content: any RealityViewContentProtocol) {
    if let modelURL = Bundle.main.url(forResource: "model_name", withExtension: "usdz") {
        Task {
            do {
                let entity = try await ModelEntity(contentsOf: modelURL)
                entity.position = [0, 0, 0]
                entity.scale = [1, 1, 1]
                
                await MainActor.run {
                    content.add(entity)
                }
            } catch {
                print("Failed to load USDZ: \\(error)")
            }
        }
    }
}
```

### Loading USDZ dari URL:
```swift
let onlineURL = URL(string: "https://example.com/model.usdz")!
let entity = try await ModelEntity(contentsOf: onlineURL)
content.add(entity)
```

## 💻 Contoh Kode Lengkap

### Basic RealityView dengan Camera Controls:
```swift
import SwiftUI
import RealityKit

struct BasicRealityView: View {
    @State private var cameraMode: CameraMode = .orbit
    
    enum CameraMode: String, CaseIterable {
        case orbit = "Orbit"
        case dolly = "Dolly"
        case pan = "Pan"
        case tilt = "Tilt"
        case none = "None"
    }
    
    var body: some View {
        VStack {
            RealityView { content in
                setupScene(content: content)
            }
            .realityViewCameraControls(getCameraControl())
            
            Picker("Camera", selection: $cameraMode) {
                ForEach(CameraMode.allCases, id: \\.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private func setupScene(content: any RealityViewContentProtocol) {
        // Add lighting
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.position = [2, 2, 2]
        content.add(light)
        
        // Add model
        let mesh = MeshResource.generateBox(size: 0.3)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        content.add(entity)
    }
    
    private func getCameraControl() -> CameraControls {
        switch cameraMode {
        case .orbit: return .orbit
        case .dolly: return .dolly
        case .pan: return .pan
        case .tilt: return .tilt
        case .none: return .none
        }
    }
}
```

### Advanced RealityView dengan USDZ:
```swift
struct USDZViewer: View {
    @State private var modelEntity: ModelEntity?
    @State private var isLoaded = false
    
    var body: some View {
        VStack {
            RealityView { content in
                loadUSDZModel(content: content)
            } update: { content in
                // Update animations atau transformations
                animateModel()
            }
            .realityViewCameraControls(.orbit)
            
            Text(isLoaded ? "✅ Model Loaded" : "⏳ Loading...")
        }
    }
    
    private func loadUSDZModel(content: any RealityViewContentProtocol) {
        guard let url = Bundle.main.url(forResource: "toy_robot", withExtension: "usdz") else {
            return
        }
        
        Task {
            do {
                let entity = try await ModelEntity(contentsOf: url)
                
                await MainActor.run {
                    content.add(entity)
                    self.modelEntity = entity
                    self.isLoaded = true
                }
            } catch {
                print("Error loading USDZ: \\(error)")
            }
        }
    }
    
    private func animateModel() {
        guard let entity = modelEntity else { return }
        
        let rotationAngle = Float(Date().timeIntervalSince1970)
        entity.orientation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
    }
}
```

## 📋 Tips dan Best Practices

### 🎯 Pemilihan Camera Mode:

| Skenario | Camera Mode | Alasan |
|----------|-------------|--------|
| Product showcase | **Orbit** | User bisa inspect dari segala sudut |
| Game character follow | **Orbit** | Karakter tetap di center |
| Architectural tour | **Pan** | Bebas explore environment |
| City building game | **Pan** | Overview development area |
| Cinematic presentation | **Dolly** | Dramatic zoom effects |
| Tutorial/Demo | **None** | Controlled viewing experience |

### 🛠️ Performance Tips:

1. **Optimize Model Size:**
   ```swift
   // Auto-scale large models
   if let bounds = entity.model?.mesh.bounds {
       let maxSize = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
       if maxSize > 2.0 {
           entity.scale = [1.0/maxSize, 1.0/maxSize, 1.0/maxSize]
       }
   }
   ```

2. **Efficient Loading:**
   ```swift
   // Load models asynchronously
   Task {
       let entity = try await ModelEntity(contentsOf: url)
       await MainActor.run {
           content.add(entity)
       }
   }
   ```

3. **Memory Management:**
   ```swift
   // Remove entities when not needed
   entity.removeFromParent()
   ```

### 🔧 Debugging Tips:

1. **Check Bundle Contents:**
   ```swift
   let usdzFiles = Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: nil)
   print("Available USDZ files: \\(usdzFiles?.map { $0.lastPathComponent } ?? [])")
   ```

2. **Error Handling:**
   ```swift
   do {
       let entity = try await ModelEntity(contentsOf: url)
       content.add(entity)
   } catch {
       print("Loading failed: \\(error.localizedDescription)")
       // Show fallback model
   }
   ```

### 📱 Platform Considerations:

- **iOS 17+**: RealityView tersedia
- **visionOS**: Full support dengan immersive experience
- **macOS**: Limited support, lebih baik untuk development
- **Simulator**: Basic support, testing di device fisik disarankan

## 🔗 Resources

- [Apple Developer - RealityKit](https://developer.apple.com/documentation/realitykit)
- [Apple Developer - RealityView](https://developer.apple.com/documentation/realitykit/realityview)
- [Apple AR Quick Look Gallery](https://developer.apple.com/augmented-reality/quick-look/)
- [USDZ Tools dan Converter](https://developer.apple.com/download/more/)

---

*Dibuat untuk membantu developer memahami RealityView dan implementasi 3D content di iOS*