import SceneKit

class LineNode: SCNNode {
    
    init(from vectorA: SCNVector3, to vectorB: SCNVector3, color: UIColor) {
        super.init()
        
        let height = self.distance(from: vectorA, to: vectorB)
        
        self.position = vectorA
        let nodeVector2 = SCNNode()
        nodeVector2.position = vectorB
        
        let nodeZAlign = SCNNode()
        nodeZAlign.eulerAngles.x = Float.pi/2
        
        let box = SCNBox(width: 0.003, height: height, length: 0.001, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = color
        box.materials = [material]
        
        let nodeLine = SCNNode(geometry: box)
        nodeLine.position.y = Float(-height/2) + 0.001
        nodeZAlign.addChildNode(nodeLine)
        
        self.addChildNode(nodeZAlign)
        self.constraints = [SCNLookAtConstraint(target: nodeVector2)]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func distance(from vectorA: SCNVector3, to vectorB: SCNVector3) -> CGFloat {
        return CGFloat(sqrt(
                pow(vectorA.x - vectorB.x, 2) +
                pow(vectorA.y - vectorB.y, 2) +
                pow(vectorA.z - vectorB.z, 2)
            )
        )
    }
    
}
