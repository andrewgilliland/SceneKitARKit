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
//            print("addPoint()")
            
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            let hitTestResults = sceneView.hitTest(screenCenter, types: .featurePoint)
                
//            print("\(hitTestResults)")
            
            if let hitResult = hitTestResults.first{
//                print("\(hitResult)")
                let nodeGeometry = SCNSphere(radius: 0.008)
                let material = SCNMaterial()
                material.diffuse.contents = option.color
                nodeGeometry.materials = [material]
                
                let node = SCNNode(geometry: nodeGeometry)
                node.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
                sceneView.scene.rootNode.addChildNode(node)
                nodes.append(node)
                
                if nodes.count >= 2 {
                    calculate()
                }
            }
        }
        
        func calculate() {
            let start = nodes[0]
            let end = nodes[1]
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
            
            lineNode.removeFromParentNode()
            lineNode = LineNode(from: start.position, to: end.position, color: UIColor.white)
            
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
