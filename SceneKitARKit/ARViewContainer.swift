import ARKit
import Combine
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var arObservable: ARObservable
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var sceneView = ARSCNView()
        private var configuration = ARWorldTrackingConfiguration()
        private var coachingOverlay = ARCoachingOverlayView()
        private var cancellables: Set<AnyCancellable> = []
        
        private var nodes:[SCNNode] = []
        private var lineNodes:[SCNNode] = []
        private var textNodes:[SCNNode] = []
        private var meter: Double?
        private var lineNode = SCNNode()
        private var textNode = SCNNode()
//        private var textMeasure = SCNNode()
        
        private var targetNode: SCNNode?
        private var targetLineNode: SCNNode?
        @ObservedObject var arObservable: ARObservable
        
        
        init(arObservable: ARObservable) {
            self.arObservable = arObservable
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
//            sceneView.showsStatistics = true

            subscribeToActionStream()
            
        }

        func renderer(_: SCNSceneRenderer, didAdd _: SCNNode, for anchor: ARAnchor) {
//            print("rendered: didAdd")
            
            guard anchor is ARPlaneAnchor else { return }
            DispatchQueue.main.async {
                self.coachingOverlay.setActive(false, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    print("coaching done")
                    self.arObservable.coachingOverlayViewDidDeactivate = true
                }
            }
        }
        
        func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
            
            DispatchQueue.main.async {
                // Remove the previously added node if it exists
                self.targetNode?.removeFromParentNode()
                self.targetLineNode?.removeFromParentNode()
                
                // Add a new node at the current frame's location
                let newTargetNode = self.addTargetNode()
                
                if self.nodes.count > 0 {
                    // Create new LineNode
                    let newTargetLineNode = LineNode(from: self.nodes.last!.position, to: newTargetNode.position, color: .green)
                    // Add new LineNode to scene
                    self.sceneView.scene.rootNode.addChildNode(newTargetLineNode)
                    // Update the distance to last node to the distance of the LineNode
                    self.arObservable.distanceToLastNode = Float(newTargetLineNode.distance(from: self.nodes.last!.position, to: newTargetNode.position))
                    // Update the reference to the added node
                    self.targetLineNode = newTargetLineNode
                }
                self.sceneView.scene.rootNode.addChildNode(newTargetNode)
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

                    case .deleteLastNode:
                        self?.deleteLastNode()
                        
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
                    let nodeGeometry = SCNSphere(radius: 0.0025)
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
//            let toCM = mark.converted(to: UnitLength.centimeters)
            let toINCH = mark.converted(to: UnitLength.inches)
            let formatter = MeasurementFormatter()
            formatter.unitOptions = .providedUnit
            formatter.numberFormatter.maximumFractionDigits = 1

            let inchString = formatter.string(from: toINCH)
            
            let centerPosition = getCenterPosition(position1: start.position, position2: end.position)
            
            updateText(text: inchString, atPosition: centerPosition)
            
            lineNode = LineNode(from: start.position, to: end.position, color: UIColor(white: 1.0, alpha: 0.5))
            
            sceneView.scene.rootNode.addChildNode(lineNode)
            lineNodes.append(lineNode)
        }
        
        func updateText(text: String, atPosition position: SCNVector3) {
//            textMeasure.removeFromParentNode()
            
//            let textGeometry = SCNText(string: text, extrusionDepth: 0.0)
//            textGeometry.font = UIFont.systemFont(ofSize: 1)
            
//            let frontMaterial = SCNMaterial()
//            frontMaterial.diffuse.contents = UIColor.blue
//            textGeometry.firstMaterial = frontMaterial
            
//            let backMaterial = SCNMaterial()
//            backMaterial.diffuse.contents = UIColor.white
//            textGeometry.materials = [frontMaterial, backMaterial]
            
//            textMeasure = SCNNode(geometry: textGeometry)
//            textMeasure.position = SCNVector3(x: position.x, y: position.y, z: position.z)
//            textMeasure.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            
            let textOutline = SCNText(string: text, extrusionDepth: 0.0)
            textOutline.font = UIFont.systemFont(ofSize: 1)
            
            let outlineMaterial = SCNMaterial()
            outlineMaterial.diffuse.contents = UIColor.gray
            textOutline.firstMaterial = outlineMaterial
            
            textNode = SCNNode(geometry: textOutline)
            textNode.position = SCNVector3(x: position.x, y: position.y, z: position.z - 0.01)
            textNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
            
            //  Radians = Degrees * (π / 180)
            let angleInRadians: Float = 0.0 * (Float.pi / 180.0)
            textNode.eulerAngles = SCNVector3(0, angleInRadians, 0)
            
//            sceneView.scene.rootNode.addChildNode(textMeasure)
            sceneView.scene.rootNode.addChildNode(textNode)
            textNodes.append(textNode)
        }
        
        func deleteLastNode() -> Void {
            print("deleteLastNode")
            let lastNode = self.nodes[nodes.count - 1]
            let lastLineNode = self.lineNodes[lineNodes.count - 1]
            let lastTextNode = self.textNodes[textNodes.count - 1]
            
            lastNode.removeFromParentNode()
            lastLineNode.removeFromParentNode()
            lastTextNode.removeFromParentNode()
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
                    
                    if let cameraNode = sceneView.pointOfView {
                        let distance = getDistance(from: cameraNode, to: node)
                        arObservable.distance = distance
                    }
                    
                    arObservable.onPlane = true
                    return node
                }
            }
            
            // Raycast fails, No plane detected
            arObservable.onPlane = false
            return SCNNode()
        }
        
        func getCurrentFramePosition() -> SCNVector3 {
            if let currentFrame = sceneView.session.currentFrame {
                let cameraPosition = SCNVector3(
                    currentFrame.camera.transform.columns.3.x,
                    currentFrame.camera.transform.columns.3.y,
                    currentFrame.camera.transform.columns.3.z)

                return cameraPosition
            }
            return SCNVector3()
        }
        
        func getDistance(from: SCNNode, to: SCNNode) -> Float {
            let distance = sqrt(
                pow(from.position.x - to.position.y, 2) +
                pow(from.position.y - to.position.y, 2) +
                pow(from.position.z - to.position.z, 2)
            )
            return distance
        }
        
        func getCenterPosition(position1: SCNVector3, position2: SCNVector3) -> SCNVector3 {
            let centerX = (position1.x + position2.x) / 2
            let centerY = (position1.y + position2.y) / 2
            let centerZ = (position1.z + position2.z) / 2
            
            return SCNVector3(centerX, centerY, centerZ)
        }
    }

    func makeUIView(context: Context) -> ARSCNView {
        context.coordinator.sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(arObservable: arObservable)
    }
}


struct Option {
    let name: String
    let color: UIColor
}
