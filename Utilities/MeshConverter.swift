//
//  MeshConverter.swift
//  LiDARMapper
//
//  Utilities for converting ARKit mesh data to RealityKit resources
//

import ARKit
import RealityKit

struct MeshConverter {

    /// Convert MeshAnchor geometry to RealityKit MeshResource
    static func meshResource(from geometry: MeshAnchor.Geometry) -> MeshResource? {
        var descriptor = MeshDescriptor()

        // Vertex positions
        let positions = geometry.vertices.asSIMD3(ofType: Float.self)
        descriptor.positions = .init(positions)

        // Normals
        let normals = geometry.normals.asSIMD3(ofType: Float.self)
        descriptor.normals = .init(normals)

        // Faces (triangles)
        let faces = geometry.faces.asUInt32Array()
        descriptor.primitives = .triangles(faces)

        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            print("❌ Failed to generate mesh resource: \(error)")
            return nil
        }
    }

    /// Convert PlaneAnchor geometry to RealityKit MeshResource
    static func planeMeshResource(from geometry: PlaneAnchor.Geometry) -> MeshResource? {
        var descriptor = MeshDescriptor()

        // Vertex positions
        let positions = geometry.meshVertices.asSIMD3(ofType: Float.self)
        descriptor.positions = .init(positions)

        // Generate simple normals (all pointing up for horizontal, or appropriate for vertical)
        let normals = positions.map { _ in SIMD3<Float>(0, 1, 0) }
        descriptor.normals = .init(normals)

        // Faces
        let faces = geometry.meshFaces.asUInt32Array()
        descriptor.primitives = .triangles(faces)

        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            print("❌ Failed to generate plane mesh resource: \(error)")
            return nil
        }
    }
}

// MARK: - Helper Extensions

extension GeometrySource {
    func asArray<T>(ofType: T.Type) -> [T] {
        assert(MemoryLayout<T>.stride == stride)
        return (0..<count).map {
            buffer.contents().advanced(by: offset + stride * $0).assumingMemoryBound(to: T.self).pointee
        }
    }

    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        asArray(ofType: (T, T, T).self).map { SIMD3($0.0, $0.1, $0.2) }
    }
}

extension GeometryElement {
    func asUInt32Array() -> [UInt32] {
        var result: [UInt32] = []
        result.reserveCapacity(count * primitive.indexCount)

        for i in 0..<count {
            for j in 0..<primitive.indexCount {
                result.append(buffer.contents().advanced(by: (i * primitive.indexCount + j) * bytesPerIndex)
                    .assumingMemoryBound(to: UInt32.self).pointee)
            }
        }
        return result
    }
}
