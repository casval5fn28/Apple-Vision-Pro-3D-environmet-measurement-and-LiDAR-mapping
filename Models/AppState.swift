//
//  AppState.swift
//  LiDARMapper
//
//  Central state manager for ARKit session and spatial tracking
//

import ARKit
import RealityKit
import SwiftUI

@MainActor
@Observable
class AppState {

    // AR Session components
    var worldTracking = WorldTrackingProvider()
    var planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
    var sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
    let arkitSession = ARKitSession()

    // Managers
    var planeManager: PlaneManager?
    var meshManager: MeshManager?

    // distance measurement manager
    var distanceRaycastManager: DistanceRaycastManager?
    // RealityKit camera transform (for raycast)
    var cameraTransform: Transform?

    // Session state
    var isSessionRunning = false
    var isImmersiveSpaceOpened = false
    var isAuthorized = false

    // Tracking data
    var devicePosition: SIMD3<Float>?
    var detectedPlaneCount = 0
    var meshAnchorCount = 0

    // measured distance (meters)
    var measuredDistance: Float?

    // Visualization settings
    var showPlanes = true
    var showMesh = true
    var meshStyle: MeshStyle = .wireframe

    // Provider lifecycle
    private func recreateProviders() {
        // Create fresh providers. Stopped providers cannot be re-run.
        worldTracking = WorldTrackingProvider()
        planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
        sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
    }

    init() {
        Task {
            await requestAuthorization()
        }
    }

    /// Request ARKit authorization for world sensing
    func requestAuthorization() async {
        let result = await arkitSession.requestAuthorization(for: [.worldSensing])

        for (authType, authStatus) in result {
            print("Authorization for \(authType): \(authStatus)")
            if authStatus == .allowed {
                isAuthorized = true
            }
        }

        if !isAuthorized {
            print("⚠️ World sensing authorization denied")
        }
    }

    /// Start the AR session with all providers
    func startSession() async {
        guard isAuthorized else {
            print("❌ Cannot start session: not authorized")
            return
        }

        guard !isSessionRunning else {
            print("ℹ️ Session already running; ignoring start request")
            return
        }

        // Recreate providers since stopped providers cannot be re-run
        recreateProviders()

        do {
            print("🚀 Starting ARKit session...")
            try await arkitSession.run([worldTracking, planeDetection, sceneReconstruction])
            isSessionRunning = true
            print("✅ ARKit session running")
        } catch {
            print("❌ Failed to start ARKit session: \(error)")
        }
    }

    /// Stop the AR session
    func stopSession() {
        guard isSessionRunning else {
            print("ℹ️ Session already stopped; ignoring stop request")
            return
        }

        // Stop the ARKit session which stops all providers
        arkitSession.stop()
        isSessionRunning = false

        // Reset state counters
        devicePosition = nil
        detectedPlaneCount = 0
        meshAnchorCount = 0
        measuredDistance = nil

        print("⏹️ ARKit session stopped")
    }

    /// Update device position from world tracking
    func updateDevicePosition() {
        guard isSessionRunning else { return }

        guard let pose = worldTracking.queryDeviceAnchor(
            atTimestamp: CACurrentMediaTime()
        ) else {
            return
        }

        let transform = pose.originFromAnchorTransform
        devicePosition = SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
    }
}
