//
//  ImmersiveView.swift
//  LiDARMapper
//
//  Main immersive view for real-time 3D mapping
//

import SwiftUI
import RealityKit
import simd
import QuartzCore
import UIKit

struct ImmersiveView: View {
    @Environment(AppState.self) private var appState

    @State private var planeTask: Task<Void, Never>?
    @State private var meshTask: Task<Void, Never>?
    @State private var deviceTask: Task<Void, Never>?
    @State private var distanceTask: Task<Void, Never>?

    // ✅ prevent RealityView setup closure from being called multiple times, which would cause duplicate manager/task creation and lead to plane toggle issues
    @State private var didSetup = false

    // Reticle + distance label in 3D
    @State private var rootEntity: Entity?
    @State private var reticleEntity: ModelEntity?
    @State private var distanceTextEntity: ModelEntity?
    

    var body: some View {
        RealityView { content in
            // RealityView setup closure may be triggered multiple times, here we must do one-time protection
            if !didSetup {
                // Root entity
                let root = Entity()
                root.name = "LiDARMapperRoot"
                content.add(root)

                // Managers
                let planeManager = PlaneManager(appState: appState, rootEntity: root)
                let meshManager  = MeshManager(appState: appState, rootEntity: root)
                appState.planeManager = planeManager
                appState.meshManager  = meshManager

                // 3D reticle + 3D distance text
                let reticle = makeReticleEntity()
                let label   = makeDistanceTextEntity(text: "-- m")
                root.addChild(reticle)
                root.addChild(label)

                self.rootEntity = root
                self.reticleEntity = reticle
                self.distanceTextEntity = label

                // Distance manager uses RealityKit scene raycast through rootEntity.scene
                let distanceManager = DistanceRaycastManager(rootEntity: root)
                appState.distanceRaycastManager = distanceManager

                // Start session
                await appState.startSession()
                try? await Task.sleep(for: .milliseconds(200))

                // Start monitoring
                planeTask = Task { await planeManager.startMonitoring() }
                meshTask  = Task { await meshManager.startMonitoring() }

                // Start device pose loop (also updates reticle pose)
                deviceTask = Task { await trackDeviceAndReticle() }

                // Start distance loop (updates label text)
                // distanceTask = Task { await trackDistanceAndLabel() }

                didSetup = true
                print("✅ ImmersiveView setup complete")
            }
        } update: { _ in
            // Keep toggles working
            
            if let planeManager = appState.planeManager {
                planeManager.setVisibility(appState.showPlanes)
            }
            if let meshManager = appState.meshManager {
                meshManager.setVisibility(appState.showMesh)
                meshManager.updateStyle(appState.meshStyle)
            }
        }
        .onDisappear {
            planeTask?.cancel(); planeTask = nil
            meshTask?.cancel(); meshTask = nil
            deviceTask?.cancel(); deviceTask = nil
            distanceTask?.cancel(); distanceTask = nil

            appState.stopSession()
            appState.planeManager?.clear()
            appState.meshManager?.clear()

            // reset so next open is clean
            didSetup = false
            rootEntity = nil
            reticleEntity = nil
            distanceTextEntity = nil
            appState.distanceRaycastManager = nil
        }
    }

    // 3D UI entities

    private func makeReticleEntity() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.01)
        var mat = UnlitMaterial()
        mat.color = .init(tint: .red)
        let e = ModelEntity(mesh: mesh, materials: [mat])
        e.name = "Reticle"
        return e
    }

    private func makeDistanceTextEntity(text: String) -> ModelEntity {
        let font = UIFont.systemFont(ofSize: 0.14, weight: .semibold)

        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: font,
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        var mat = UnlitMaterial()
        mat.color = .init(tint: .white)

        let e = ModelEntity(mesh: mesh, materials: [mat])
        e.name = "DistanceLabel"
        e.scale = SIMD3<Float>(repeating: 0.25)
        return e
    }

    private func updateDistanceText(_ entity: ModelEntity, text: String) {
        let font = UIFont.systemFont(ofSize: 0.14, weight: .semibold)
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: font,
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        entity.model?.mesh = mesh
    }

    // loops

    /// Track device pose and keep the reticle/label fixed in the center of view.
    private func trackDeviceAndReticle() async {
        var firstSampleObtained = false
        var lastText = "" 
        var smoothedDistance: Float = 0

        while !Task.isCancelled {
            guard appState.isSessionRunning else {
                try? await Task.sleep(for: .milliseconds(100))
                continue
            }

            guard let deviceAnchor = appState.worldTracking.queryDeviceAnchor(
                atTimestamp: CACurrentMediaTime()
            ) else {
                if !firstSampleObtained {
                    try? await Task.sleep(for: .milliseconds(150))
                    continue
                }
                try? await Task.sleep(for: .milliseconds(100))
                continue
            }

            firstSampleObtained = true
            appState.updateDevicePosition()

            let t = deviceAnchor.originFromAnchorTransform
            let origin = SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            let forward = -SIMD3<Float>(t.columns.2.x, t.columns.2.y, t.columns.2.z)

            // ===== reticle + label position (declare once, then use for billboard) =====
            var labelPos: SIMD3<Float>

            if let manager = appState.distanceRaycastManager,
               let result = manager.measureDistance(origin: origin, direction: forward) {

                let hitPos = result.hitPosition
                reticleEntity?.position = hitPos

                labelPos = origin + forward * 1.0   //modified  //hitPos + SIMD3<Float>(0, 0.07, 0)
                distanceTextEntity?.position = labelPos
                
                // smooth the displayed distance to avoid jitter, using simple low-pass filter
                let alpha: Float = 0.2
                smoothedDistance = alpha * result.distance + (1 - alpha) * smoothedDistance
                
                let newText = String(format: "%.2f m", smoothedDistance)

                // only update mesh when number changes, to avoid flickering
                if newText != lastText {
                    if let label = distanceTextEntity {
                        updateDistanceText(label, text: newText)
                    }
                    lastText = newText//new
                }

            } else {
                let fallbackPos = origin + forward * 1.0
                reticleEntity?.position = fallbackPos

                labelPos = fallbackPos 
                distanceTextEntity?.position = labelPos
                
                if lastText != "-- m" {
                    if let label = distanceTextEntity {
                        updateDistanceText(label, text: "-- m")
                    }
                    lastText = "-- m"
                }
            }

            // ===== Billboard label to face user =====
            if let label = distanceTextEntity {
                label.look(at: origin, from: labelPos, relativeTo: nil)
                label.orientation *= simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
            }

            try? await Task.sleep(for: .milliseconds(60))
        }
    }
}

#Preview {
    ImmersiveView()
        .environment(AppState())
}
