import ARKit
import Combine
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var sceneView = ARSCNView()
        private var configuration = ARWorldTrackingConfiguration()
        private var coachingOverlay = ARCoachingOverlayView()
        private var cancellables: Set<AnyCancellable> = []
        
        private var nodes:[SCNNode] = []
        private var meter: Double?
        private var lineNode = SCNNode()
        private var textMeasure = SCNNode()
        private var outlineNode = SCNNode()
        
        private var targetNode: SCNNode?
        
        override init() {
            super.init()

            configuration.environmentTexturing = .automatic
            configuration.planeDetection = [.horizontal]
            configuration.worldAlignment = ARConfiguration.WorldAlignment.gravity

            sceneView.session.run(configuration)
            sceneView.delegate = self
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
        
        func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
            DispatchQueue.main.async {
                
                // Remove the previously added node if it exists
                self.targetNode?.removeFromParentNode()
                
                // Add a new node at the current frame's location
                let newTargetNode = self.addTargetNode()
                self.sceneView.scene.rootNode.addChildNode(newTargetNode)
                
                // Update the reference to the added node
                self.targetNode = newTargetNode
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
                        print("delete last node")

                    case .removeAllAnchors:
                        print("delete all node")
                    }
                }
                .store(in: &cancellables)
        }

        func addNode(option: Option) {
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
            if let raycastQuery = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any) {
                let results = sceneView.session.raycast(raycastQuery)
                
                if let result = results.first {
                    let nodeGeometry = SCNSphere(radius: 0.004)
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor(white: 1.0, alpha: 0.9)
                    nodeGeometry.materials = [material]
                    
                    let node = SCNNode(geometry: nodeGeometry)
                    node.position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                    sceneView.scene.rootNode.addChildNode(node)
                    nodes.append(node)
                    
                    if nodes.count >= 2 {
                        calculate()
                    }
                }
            }
        }
        
        func calculate() {
            let start = nodes[nodes.count - 2]
            let end = nodes[nodes.count - 1]
            let distance = sqrt(
                pow(end.position.x - start.position.x, 2) +
                pow(end.position.y - start.position.y, 2) +
                pow(end.position.z - start.position.z, 2)
            )
            
            meter = Double(abs(distance))
            
            let mark = Measurement(value: meter ?? 0, unit: UnitLength.meters)
            let toCM = mark.converted(to: UnitLength.centimeters)
            
            let value = "\(toCM)"
            let finalValue = String(value.prefix(5)) + "CM"
            
            updateText(text: finalValue, atPosition: end.position)
            
            lineNode = LineNode(from: start.position, to: end.position, color: UIColor(white: 1.0, alpha: 0.5))
            
            sceneView.scene.rootNode.addChildNode(lineNode)
            
        }
        
        func updateText(text: String, atPosition position: SCNVector3) {
            textMeasure.removeFromParentNode()
            
            let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
            textGeometry.font = UIFont.systemFont(ofSize: 10)
            
            let textOutline = SCNText(string: text, extrusionDepth: 0.5)
            textOutline.font = UIFont.systemFont(ofSize: 10)
            
            let frontMaterial = SCNMaterial()
            frontMaterial.diffuse.contents = UIColor.red
            textGeometry.firstMaterial = frontMaterial
            
            let backMaterial = SCNMaterial()
            backMaterial.diffuse.contents = UIColor.black
            textGeometry.materials = [frontMaterial, backMaterial]
            
            textMeasure = SCNNode(geometry: textGeometry)
            textMeasure.position = SCNVector3(x: position.x, y: position.y, z: position.z)
            textMeasure.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            
            let outlineMaterial = SCNMaterial()
            outlineMaterial.diffuse.contents = UIColor.black
            textOutline.firstMaterial = outlineMaterial
            
            outlineNode = SCNNode(geometry: textOutline)
            outlineNode.position = SCNVector3(x: position.x, y: position.y + 0.0148, z: position.z - 0.01)
            outlineNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            
            sceneView.scene.rootNode.addChildNode(textMeasure)
            sceneView.scene.rootNode.addChildNode(outlineNode)
        }
        
        func addTargetNode() -> SCNNode {
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
            if let raycastQuery = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any) {
                let results = sceneView.session.raycast(raycastQuery)
                
                if let result = results.first {
                    let nodeGeometry = SCNSphere(radius: 0.005)
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.green
                    nodeGeometry.materials = [material]
                    
                    let node = SCNNode(geometry: nodeGeometry)
                    node.position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                    return node
                }
            }
            
            // if this returns disable add button
            return SCNNode()
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
