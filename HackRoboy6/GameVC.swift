import Foundation
import UIKit
import ARKit
import SceneKit
import Vision

class GameVC: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet var sceneView: ARSCNView!
    
    var cameraPosition = SCNVector3(0, 0, 0)
    var calibrateOriginalCameraPos: SCNVector3? = nil
    var calibrateOriginalRootPos: SCNVector3? = nil
    
    var coordinateCount: Int {
        return 5
    }
    var coordinateIterator: Int = 0
    struct Coordinate {
        var x: Double
        var y: Double
    }
    var coordinateBuffer = [Coordinate?](repeating: nil, count: 5)
    
    var gameBoard: SCNNode!
    var roboyNode: SCNNode!
    var enemyNodes: [SCNNode] = []
    var iceCreamNode: SCNNode!
    var uiLivesNodes: SCNNode!
    var uiCollectedNodes: SCNNode!
    var lastIceCreamPos: SCNVector3 = SCNVector3Zero
    
    var activeOpenCV: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load Roboy Node
        let ufoScene = SCNScene(named: "RoboyUfo.dae")
        let ufoNode = ufoScene?.rootNode.childNode(withName: "UFO", recursively: true)
        ufoNode?.scale = SCNVector3Make(0.015, 0.015, 0.015)
        
        roboyNode = ufoNode
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        let initialScene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = initialScene
        
        self.loadBoard()
        
        self.uiLivesNodes = self.createTextNode(string: "Lives: 3", pos: SCNVector3Make(0.012, 0.0168, -0.06))
        self.sceneView.scene.rootNode.addChildNode(self.uiLivesNodes)
        self.uiCollectedNodes = self.createTextNode(string: "Ice: 0/15", pos: SCNVector3Make(-0.030, 0.0168, -0.06))
        self.sceneView.scene.rootNode.addChildNode(self.uiCollectedNodes)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 0)
        self.sceneView.scene.rootNode.addChildNode(lightNode)
        
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
        self.sceneView.scene.rootNode.addChildNode(ambientLightNode)
        
        //GameController.shared().startGame()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = AROrientationTrackingConfiguration()
        
        //configuration.planeDetection = [.horizontal, .vertical]
        
        configuration.isAutoFocusEnabled = true
        
        configuration.worldAlignment = .camera
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func loadBoard() {
        
        // Reset Current Tracking
        if let pointOfView = self.sceneView.pointOfView {
            
            let conv_transformMat = SCNMatrix4ToGLKMatrix4(pointOfView.transform)
            let conv_rotatedTransformMat = GLKMatrix4RotateX(conv_transformMat, 1.0472) // 1.0472 to correct angle of base station
            let transformMat = SCNMatrix4FromGLKMatrix4(conv_rotatedTransformMat)
            
            self.sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4(transformMat))
        } else { return }
        
        
        let translateMat = SCNMatrix4MakeTranslation(0.01, 0.02, -0.23) // -2.16, -2.86 ------ 07. Juli:  0.35, -2.85
        let rotateMat = SCNMatrix4MakeRotation(0 * (.pi / 180.0), 1, 0, 0)
        let scaleMat = SCNMatrix4MakeScale(1, 1, 1)
        
        let board: SCNPlane = SCNPlane(width: 0.14, height: 0.14) // 2.62
        self.gameBoard = SCNNode(geometry: board)
        self.gameBoard.transform = SCNMatrix4Mult(translateMat, SCNMatrix4Mult(rotateMat, scaleMat))
        self.gameBoard.geometry?.firstMaterial?.transparency = 0.000001 //0.000001
        //self.gameBoard.opacity = 1
        
        let orientation = self.gameBoard.orientation
        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        
        // Rotate around Z axis
        let multiplier = GLKQuaternionMakeWithAngleAndAxis(-30 * (.pi / 180.0), 1, 0, 0) // -38
        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)
        
        self.gameBoard.orientation = SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
        
        self.gameBoard.name = "GameBoard"
        
        // Add Roboy
        self.sceneView.scene.rootNode.addChildNode(self.roboyNode)
        
        // Add Board
        self.sceneView.scene.rootNode.addChildNode(self.gameBoard)
    }
    
    func createTextNode(string: String, pos: SCNVector3) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.2)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.005
        text.firstMaterial?.diffuse.contents = UIColor.red
        
        let textNode = SCNNode(geometry: text)
        
        let fontSize = Float(0.005)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        textNode.position = pos
        return textNode
    }
    
    
    
}
