## Abstract
Most existing forest measurements remain dependent on manual instruments or labor-required methods that are limited in efficiency. With the emergence of LiDAR-enabled head-mounted devices, immersive spatial computing offers a new opportunity for real-time environmental interaction. However, few systems currently leverage these platforms for practical forestry measurement applications.

So I present an immersive LiDAR-based forest measurement system built on Apple Vision Pro (AVP) that enables gaze-aligned, accurate real-time distance estimation within reconstructed 3D environments.

By synchronizing device pose tracking with spatial mesh raycasting, the application allows users to measure trees and surrounding structures directly in immersive space. With this foundation, we can move on to integrate semantic tree segmentation into head-mounted spatial computing workflows, moving toward intelligent and easy-to use forest inventory tools.

## METHODS

# 1.Real-Time World Tracking
-Continuous retrieval of device anchor transform (4×4 matrix)
-Extraction of user world pos. and forward viewing direction
-Frame-by-frame pose update for spatial alignment

# 2.LiDAR-Based Scene Reconstruction
-System-level LiDAR + visual tracking
-Generation of MeshAnchors
-RealityKit scene reconstruction
-Raycast queries against dynamic spatial mesh

# 3.Gaze-Aligned Raycasting
-Forward vector derived from device -Z axis
-Raycast from user position into reconstructed mesh
-Nearest-hit intersection query
-Euclidean distance computation

## Next Steps
Integrate tree-instance segmentation model
Perform real-time trunk detection
Perform real-time DBH measurement
Improve robustness in sparse mesh conditions
