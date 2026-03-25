# Abstract
Most existing forest measurements remain dependent on manual instruments or labor-required methods that are limited in efficiency. With the emergence of LiDAR-enabled head-mounted devices, immersive spatial computing offers a new opportunity for real-time environmental interaction. However, few systems currently leverage these platforms for practical forestry measurement applications.

So I present an immersive LiDAR-based forest measurement system built on Apple Vision Pro (AVP) that enables gaze-aligned, accurate real-time distance estimation within reconstructed 3D environments.

By synchronizing device pose tracking with spatial mesh raycasting, the application allows users to measure trees and surrounding structures directly in immersive space. With this foundation, we can move on to integrate semantic tree segmentation into head-mounted spatial computing workflows, moving toward intelligent and easy-to use forest inventory tools.

# Key Highlights:
- **Real-Time Statistics**: Real-time distance measurement, live plane/mesh counts, and device position tracking
- **Expandable Mixed Reality**: AR meshes persist as you walk around your entire space (you can eventually create a large mesh of the whole scene)
- **Color-Coded Surfaces**: Automatic classification (floors, walls, ceilings, furniture)

# Features
## Core Capabilities
- **Real-Time Plane Detection**
  - Detects horizontal & vertical surfaces
  - Identifies ceiling planes
  - Colored by surface type
    
- **Real-Time Distance Measurement**
  - Compute the distance between user and target object by raycasting
  - Available for distance within at least 15 meters.
  - Automatic and smooth updates
    
- **Scene Reconstruction**
  - Generates detailed 3D mesh by AVP's LiDAR
  - Classification-based visualization
  - Adaptive mesh updates

- **Live Device Tracking**
  - Shows device position in 3D space (X, Y, Z coordinates)
  - Continuous world tracking
  - Automatic coordinate updates

---
## Used visionOS SDKs
- **SwiftUI** : Modern UI with immersive spaces
- **RealityKit** : 3D rendering and physics simulation
- **ARKitSession** : Manages ARKit data providers
- **WorldTrackingProvider** : Device position and orientation tracking
- **PlaneDetectionProvider** : Surface detection and classification
- **SceneReconstructionProvider** : Detailed mesh generation

---
## Requirements
### Hardware
- **Apple Vision Pro** (physical device required, simulator is not available)

### Software
- **Xcode 16+** with visionOS 26

---
## Visualization Results
### Scene Meshes
- **Wireframe** - Build the mesh with triangles
- **Solid** - Opaque colored mesh with lighting
- **Transparent** - Semi-transparent version of "Solid"

### Colored-Surfaces
- 🔵 **Blue** - Floors and horizontal surfaces
- 🟠 **Orange** - Walls and vertical surfaces
- 🟣 **Purple** - Ceilings
- 🟢 **Green** - Tables and desks
- 🟡 **Yellow** - Seats and chairs

---
# METHODS
- **1.Real-Time World Tracking**
  - Continuous retrieval of device anchor transform (4×4 matrix)
  - Extraction of user world pos. and forward viewing direction
  - Frame-by-frame pose update for spatial alignment

- **2.LiDAR-Based Scene Reconstruction**
  - System-level LiDAR + visual tracking
  - Generation of MeshAnchors
  - RealityKit scene reconstruction
  - Raycast queries against dynamic spatial mesh

- **3.Gaze-Aligned Raycasting**
  - Forward vector derived from device -Z axis
  - Raycast from user position into reconstructed mesh
  - Nearest-hit intersection query
  - Euclidean distance computation

---
# Next Steps
  - Integrate tree-instance segmentation model
  - Perform real-time trunk detection
  - Perform real-time DBH measurement
  - Improve robustness in sparse mesh conditions
