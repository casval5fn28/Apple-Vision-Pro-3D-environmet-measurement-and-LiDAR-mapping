//
//  MeshManager.swift
//  LiDARMapper
//
//  Manages scene reconstruction mesh visualization
//

import ARKit
import RealityKit

@MainActor
class MeshManager {
    private weak var appState: AppState?
    private var meshEntities: [UUID: ModelEntity] = [:]
    private let rootEntity: Entity

    // Monitoring tasks
    private var meshProducerTask: Task<Void, Never>?
    private var meshConsumerTask: Task<Void, Never>?

    init(appState: AppState, rootEntity: Entity) {
        self.appState = appState
        self.rootEntity = rootEntity
    }

    /// Start monitoring mesh updates
    func startMonitoring() async {
        // Capture a strong local reference to AppState first (no actor hop yet)
        guard let appState = self.appState else { return }
        // Access MainActor-isolated provider synchronously (class is MainActor)
        let provider = appState.sceneReconstruction

        print("👀 MeshManager: Starting to monitor mesh updates...")

        // Create a stream/continuation pair to bridge between background producer and MainActor consumer
        let (stream, continuation) = AsyncStream<AnchorUpdate<MeshAnchor>>.makeStream()

        // Producer: consume provider updates off-main and yield into the stream
        meshProducerTask = Task {
            for await update in provider.anchorUpdates {
                if Task.isCancelled { break }
                continuation.yield(update)
            }
            continuation.finish()
        }

        // Consumer: run on MainActor and perform RealityKit/AppState mutations
        meshConsumerTask = Task { @MainActor in
            for await update in stream {
                await self.handleMeshUpdate(update)
            }
        }
    }

    /// Stop monitoring mesh updates
    func stopMonitoring() {
        meshProducerTask?.cancel(); meshProducerTask = nil
        meshConsumerTask?.cancel(); meshConsumerTask = nil
    }

    /// Handle mesh anchor updates
    @MainActor
    private func handleMeshUpdate(_ update: AnchorUpdate<MeshAnchor>) async {
        guard let appState = appState else { return }

        let anchor = update.anchor

        switch update.event {
        case .added:
            await addMesh(anchor)
            appState.meshAnchorCount = meshEntities.count

        case .updated:
            await updateMesh(anchor)

        case .removed:
            removeMesh(anchor)
            appState.meshAnchorCount = meshEntities.count
        }
    }

    /// Add a new mesh entity
    @MainActor
    private func addMesh(_ anchor: MeshAnchor) async {
        guard let meshResource = MeshConverter.meshResource(from: anchor.geometry) else {
            print("⚠️ Failed to create mesh resource for mesh \(anchor.id)")
            return
        }

        guard let appState = appState else { return }

        // Generate collision shape for physics
        let shape: ShapeResource
        do {
            shape = try await ShapeResource.generateStaticMesh(from: anchor)
        } catch {
            print("⚠️ Failed to generate collision shape: \(error)")
            return
        }

        // Use default classification since API changed in visionOS 2
        let material = MaterialProvider.meshMaterial(
            for: .none,
            style: appState.meshStyle
        )

        let entity = ModelEntity(mesh: meshResource, materials: [material])
        entity.name = "Mesh-\(anchor.id)"

        // Set transform from anchor
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)

        // Add collision component for physics interaction
        entity.collision = CollisionComponent(shapes: [shape])
        entity.physicsBody = PhysicsBodyComponent(mode: .static)

        meshEntities[anchor.id] = entity
        rootEntity.addChild(entity)

        print("➕ Added mesh anchor (\(anchor.id))")
    }

    /// Update an existing mesh entity
    @MainActor
    private func updateMesh(_ anchor: MeshAnchor) async {
        guard let entity = meshEntities[anchor.id] else { return }
        guard let appState = appState else { return }

        // Update mesh
        if let meshResource = MeshConverter.meshResource(from: anchor.geometry) {
            // Use default classification since API changed in visionOS 2
            let material = MaterialProvider.meshMaterial(
                for: .none,
                style: appState.meshStyle
            )
            entity.model?.mesh = meshResource
            entity.model?.materials = [material]
        }

        // Update transform
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)

        // Update collision shape
        // ✅ Re-assign full CollisionComponent (NOT just modify shapes)
        if let shape = try? await ShapeResource.generateStaticMesh(from: anchor) {
            entity.collision = CollisionComponent(shapes: [shape])
            entity.physicsBody = PhysicsBodyComponent(mode: .static)
        }

    }

    /// Remove a mesh entity
    @MainActor
    private func removeMesh(_ anchor: MeshAnchor) {
        guard let entity = meshEntities.removeValue(forKey: anchor.id) else { return }
        entity.removeFromParent()
        print("➖ Removed mesh: \(anchor.id)")
    }

    /// Toggle mesh visibility
    @MainActor
    func setVisibility(_ visible: Bool) {
        for entity in meshEntities.values {
            entity.isEnabled = visible
        }
    }

    /// Update mesh visualization style
    @MainActor
    func updateStyle(_ style: MeshStyle) {
        for (_, entity) in meshEntities {
            // Get the classification from the anchor
            // Since we don't have direct access to anchor here, use a default material
            let material: any RealityKit.Material = switch style {
            case .wireframe:
                MaterialProvider.wireframeMaterial()
            case .solid:
                MaterialProvider.solidMeshMaterial()
            case .transparent:
                MaterialProvider.transparentMeshMaterial()
            }

            entity.model?.materials = [material]
        }
    }

    /// Clear all meshes
    @MainActor
    func clear() {
        stopMonitoring()
        for entity in meshEntities.values {
            entity.removeFromParent()
        }
        meshEntities.removeAll()
    }
}
