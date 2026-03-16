//
//  ContentView.swift
//  LiDARMapper
//
//  Main window view with controls and information display
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Text("LiDAR Mapper")
                    .font(.extraLargeTitle)
                    .fontWeight(.bold)

                Text("Real-time 3D Spatial Mapping")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Status
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Circle()
                        .fill(appState.isSessionRunning ? .green : .red)
                        .frame(width: 12, height: 12)
                    Text(appState.isSessionRunning ? "AR Session Active" : "AR Session Inactive")
                        .font(.headline)
                }

                if appState.isSessionRunning {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Planes: \(appState.detectedPlaneCount)")
                        Text("Mesh Anchors: \(appState.meshAnchorCount)")
                        Text("Device Position: \(formatPosition(appState.devicePosition))")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)

            Divider()

            // Controls
            VStack(spacing: 20) {
                Text("Visualization Controls")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("Show Planes", isOn: $appState.showPlanes)
                    .toggleStyle(.switch)

                Toggle("Show Mesh", isOn: $appState.showMesh)
                    .toggleStyle(.switch)

                if appState.showMesh {
                    Picker("Mesh Style", selection: $appState.meshStyle) {
                        Text("Wireframe").tag(MeshStyle.wireframe)
                        Text("Solid").tag(MeshStyle.solid)
                        Text("Transparent").tag(MeshStyle.transparent)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)

            Spacer()

            // Action Button
            Button {
                Task {
                    if appState.isImmersiveSpaceOpened {
                        await dismissImmersiveSpace()
                        appState.isImmersiveSpaceOpened = false
                    } else {
                        await openImmersiveSpace(id: "ImmersiveSpace")
                        appState.isImmersiveSpaceOpened = true
                    }
                }
            } label: {
                Text(appState.isImmersiveSpaceOpened ? "Stop Mapping" : "Start Mapping")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }

    private func formatPosition(_ position: SIMD3<Float>?) -> String {
        guard let pos = position else { return "Unknown" }
        return String(format: "X: %.2f, Y: %.2f, Z: %.2f", pos.x, pos.y, pos.z)
    }
}

enum MeshStyle: String, Codable, CaseIterable {
    case wireframe
    case solid
    case transparent
}

#Preview {
    ContentView()
        .environment(AppState())
}
