import ARKit
import Combine
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var sceneView = ARSCNView()
        private var configuration = ARWorldTrackingConfiguration()
        private var coachingOverlay = ARCoachingOverlayView()
        private var cancellables: Set<AnyCancellable> = []

        override init() {
            super.init()

            configuration.environmentTexturing = .automatic
            configuration.planeDetection = [.horizontal]
            configuration.worldAlignment = ARConfiguration.WorldAlignment.gravity

            sceneView.delegate = self
            sceneView.session.run(configuration)
            sceneView.layer.masksToBounds = true

            coachingOverlay.session = sceneView.session
            coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            coachingOverlay.goal = .horizontalPlane
            coachingOverlay.activatesAutomatically = false
            coachingOverlay.setActive(true, animated: true)

            sceneView.addSubview(coachingOverlay)

            subscribeToActionStream()
        }

        func renderer(_: SCNSceneRenderer, didAdd _: SCNNode, for anchor: ARAnchor) {
            guard anchor is ARPlaneAnchor else { return }
            DispatchQueue.main.async {
                self.coachingOverlay.setActive(false, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    print("coaching done")
                }
            }
        }
        
        func subscribeToActionStream() {
            ARManager.shared
                .actionStream
                .sink { [weak self] action in

                    switch action {
                    case let .addNode(option):
                        self?.addNode(option: option)

                    case .deleteLastPoint:

                        print("delete last plant")

                    case .removeAllAnchors:

                        print("delete all plants")
                    }
                }
                .store(in: &cancellables)
        }

        func addNode(option: Option) {
            print("addPoint()")
            
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            let hitTestResults = sceneView.hitTest(screenCenter, types: .featurePoint)
                
            print("\(hitTestResults)")
            
            if let hitResult = hitTestResults.first{
                print("\(hitResult)")
                let nodeGeometry = SCNSphere(radius: 0.008)
                let material = SCNMaterial()
                material.diffuse.contents = option.color
                nodeGeometry.materials = [material]
                
                let node = SCNNode(geometry: nodeGeometry)
                node.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
                sceneView.scene.rootNode.addChildNode(node)
    //            nodes.append(node)
            }
            
        }
    }

    func makeUIView(context: Context) -> ARSCNView {
        context.coordinator.sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}


struct Option {
    let name: String
    let color: UIColor
}
