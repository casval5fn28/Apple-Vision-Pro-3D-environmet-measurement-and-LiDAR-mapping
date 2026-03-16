//
//  MaterialProvider.swift
//  LiDARMapper
//
//  Provides materials for visualization of planes and meshes
//

import ARKit
import RealityKit
import SwiftUI

struct MaterialProvider {

    // MARK: - Plane Materials

    /// Material for horizontal planes (floors, tables)
    static func horizontalPlaneMaterial() -> UnlitMaterial {
        var material = UnlitMaterial()
        material.color = .init(tint: .blue.withAlphaComponent(0.3))
        return material
    }

    /// Material for vertical planes (walls)
    static func verticalPlaneMaterial() -> UnlitMaterial {
        var material = UnlitMaterial()
        material.color = .init(tint: .orange.withAlphaComponent(0.3))
        return material
    }

    /// Material based on plane classification
    static func planeMaterial(for classification: PlaneAnchor.Classification, alignment: PlaneAnchor.Alignment) -> UnlitMaterial {
        var material = UnlitMaterial()

        let color: UIColor = switch (classification, alignment) {
        case (.floor, _):
            .systemBlue
        case (.ceiling, _):
            .systemPurple
        case (.wall, _):
            .systemOrange
        case (.table, _):
            .systemGreen
        case (.seat, _):
            .systemYellow
        case (_, .horizontal):
            .systemBlue
        case (_, .vertical):
            .systemOrange
        default:
            .systemGray
        }

        material.color = .init(tint: color.withAlphaComponent(0.4))
        return material
    }

    // Mesh Materials

    /// Wireframe material for mesh visualization
    static func wireframeMaterial() -> UnlitMaterial {
        var material = UnlitMaterial()
        material.color = .init(tint: .cyan.withAlphaComponent(0.6))
        material.triangleFillMode = .lines
        return material
    }

    /// Solid material for mesh visualization
    static func solidMeshMaterial() -> SimpleMaterial {
        var material = SimpleMaterial()
        material.color = .init(tint: .cyan.withAlphaComponent(0.8))
        material.roughness = .init(floatLiteral: 0.5)
        return material
    }

    /// Transparent material for mesh visualization
    static func transparentMeshMaterial() -> UnlitMaterial {
        var material = UnlitMaterial()
        material.color = .init(tint: .cyan.withAlphaComponent(0.2))
        material.blending = .transparent(opacity: 0.2)
        return material
    }

    /// Material based on mesh classification
    static func meshMaterial(for classification: MeshAnchor.MeshClassification, style: MeshStyle) -> any RealityKit.Material {
        let baseColor: UIColor = switch classification {
        case .wall:
            .systemOrange
        case .floor:
            .systemBlue
        case .ceiling:
            .systemPurple
        case .table:
            .systemGreen
        case .seat:
            .systemYellow
        case .door:
            .systemBrown
        case .window:
            .systemCyan
        default:
            .systemGray
        }

        switch style {
        case .wireframe:
            var material = UnlitMaterial()
            material.color = .init(tint: baseColor.withAlphaComponent(0.8))
            material.triangleFillMode = .lines
            return material

        case .solid:
            var material = SimpleMaterial()
            material.color = .init(tint: baseColor.withAlphaComponent(0.9))
            material.roughness = .init(floatLiteral: 0.5)
            return material

        case .transparent:
            var material = UnlitMaterial()
            material.color = .init(tint: baseColor.withAlphaComponent(0.3))
            material.blending = .transparent(opacity: 0.3)
            return material
        }
    }
}
