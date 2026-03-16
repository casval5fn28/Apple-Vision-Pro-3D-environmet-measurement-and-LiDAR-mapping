import RealityKit
import simd

@MainActor
final class DistanceRaycastManager {

    private weak var rootEntity: Entity?

    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
    }

    func measureDistance(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>
    ) -> (distance: Float, hitPosition: SIMD3<Float>)? {

        guard let scene = rootEntity?.scene else {
            return nil
        }

        let hits = scene.raycast(
            origin: origin,
            direction: direction,
            length: 30.0,
            query: .nearest,
            mask: .all
        )

        guard let hit = hits.first else {
            return nil
        }

        let distance = simd_distance(origin, hit.position)
        return (distance, hit.position)
    }
}
