import Foundation
import ARKit
import SceneKit
import UIKit
import Vision

extension GameVC {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if(!self.activeOpenCV) {
            DispatchQueue.global().async {
                self.activeOpenCV = true
                
                //let image = self.convertToUIImage(buffer: frame.capturedImage)
                let image = UIImage(pixelBuffer: frame.capturedImage)
                if let _image = image {
                    let pixelCoords: String = GameController.shared().openCVWrapper.displayPosition(ofMarker: _image)
                    
                    
                    
                    if(pixelCoords != "-1:-1") {
                        var pixelCoordsSplit = pixelCoords.components(separatedBy: ":")
                        guard var x = Double(pixelCoordsSplit[0]) else { return }
                        guard var y = Double(pixelCoordsSplit[1]) else { return }
                        
                        if var _ = self.coordinateBuffer[self.coordinateIterator] {
                            self.coordinateBuffer[self.coordinateIterator] = Coordinate(x: x, y: y)

                        } else {
                            self.coordinateBuffer = [Coordinate?](repeating: Coordinate(x: x, y: y), count: 5)
                        }
                            
                        self.coordinateIterator = (self.coordinateIterator + 1) % self.coordinateCount
                        
                        var averageCoord: Coordinate = Coordinate(x: 0, y: 0)
                        for coordinate in self.coordinateBuffer {
                            averageCoord.x += coordinate!.x
                            averageCoord.y += coordinate!.y
                        }
                        x = averageCoord.x / Double(self.coordinateCount)
                        y = averageCoord.y / Double(self.coordinateCount)
                        
                        let normal = SCNMatrix4MakeRotation(-38 * (.pi / 180.0), 1, 0, 0) * SCNVector3Make(0, 0, 1)
                        var ray = simd_mul(simd_inverse(frame.camera.intrinsics), simd_float3(Float(x), Float(y), 1.0))
                        let t = self.gameBoard.worldPosition.dotProduct(normal) / (simd_dot(ray, simd_float3(normal)))
                        let p = SCNVector3Make(-ray.x * t, ray.y * t, ray.z * t)
                        
                        self.roboyNode.position = p
                    }
                    
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: {
            self.activeOpenCV = false
        })
    }
    
    
    /// This method converts an CVPixelBuffer to an UIImage to be used by OpenCV
    ///
    /// - Parameter buffer: the pixel buffer of the current frame
    /// - Returns: an UIImage to be used by OpenCV
    func convertToUIImage(buffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let temporaryContext = CIContext(options: nil)
        if let temporaryImage = temporaryContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)))
        {
            return UIImage(cgImage: temporaryImage)
        }
        return nil
    }
    
    /// This method is called every frame, right before the next frame is rendered
    ///
    /// - Parameters:
    ///   - renderer: the current renderer
    ///   - scene: the current scene
    ///   - time: the current time, relative to start of session
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if let pointOfView = sceneView.pointOfView {
            cameraPosition = SCNVector3(pointOfView.transform.m41, pointOfView.transform.m42, pointOfView.transform.m43)
        }
    }
    
    func spawnEnemy() {
        if(self.gameBoard == nil) {
            return
        }
        
        let tmpShipScene = SCNScene(named: "EnemyUfo2.dae")
        let tmpShipNode = tmpShipScene?.rootNode.childNode(withName: "UFO", recursively: true)
        guard let tmpNode = tmpShipNode else { return }
        tmpNode.scale = SCNVector3Make(0.006, 0.006, 0.006)
        
        /*let tmpSphere = SCNSphere(radius: 0.05)
        tmpSphere.materials.first?.diffuse.contents = UIColor.yellow
        let tmpNode = SCNNode(geometry: tmpSphere)*/
        
        let start: Float = Float.random(in: 0 ..< 4)
        let startCoordinates = self.spawnEnemyHelper(start: start)
        var end: Float = 0.0
        
        
        repeat {
            end = Float.random(in: 0 ..< 4)
        } while(Int(end) == Int(start))
        
        /*repeat {
            end = Float.random(in: 0 ..< 4)
        } while((abs((end + 1).truncatingRemainder(dividingBy: 4) - start) < 1) || (abs((end + 3).truncatingRemainder(dividingBy: 4)) - start) < 1)*/
        
        let endCoordinates = self.spawnEnemyHelper(start: end)
        
        tmpNode.position = startCoordinates
        
        self.enemyNodes.append(tmpNode)
        self.gameBoard.addChildNode(tmpNode)
        let travelDistance: Float = startCoordinates.distance(vector: endCoordinates)
        let maxDistance: Float = self.gameBoard.boundingBox.max.distance(vector: self.gameBoard.boundingBox.min)
        let travelTime: Double = Double.random(in: 8 ..< 11) * Double(travelDistance / maxDistance) * pow(0.75, Double(GameController.shared().playerData.difficulty))
        let travelTimeInt: Int = Int(round(travelTime * 1000.0))
        let moveToAction = SCNAction.move(to: endCoordinates, duration: travelTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(travelTimeInt)) {
            tmpNode.removeFromParentNode()
        }
        //tmpNode.look(at: endCoordinates)
        tmpNode.runAction(moveToAction)
    }
    
    func spawnEnemyHelper(start: Float) -> SCNVector3 {
        let p1 = SCNVector3(self.gameBoard.boundingBox.min.x, self.gameBoard.boundingBox.min.y, 0)
        let p2 = SCNVector3(self.gameBoard.boundingBox.min.x, self.gameBoard.boundingBox.max.y, 0)
        let p3 = SCNVector3(self.gameBoard.boundingBox.max.x, self.gameBoard.boundingBox.max.y, 0)
        let p4 = SCNVector3(self.gameBoard.boundingBox.max.x, self.gameBoard.boundingBox.min.y, 0)
        
        let side: Int = Int(start)
        let alpha: Float = start - Float(side)
        
        var startCoordinates: SCNVector3 = SCNVector3Make(0, 0, 0)
        switch(side) {
        case 0:
            startCoordinates = p1 * alpha + p2 * (1 - alpha)
            break
        case 1:
            startCoordinates = p2 * alpha + p3 * (1 - alpha)
            break
        case 2:
            startCoordinates = p3 * alpha + p4 * (1 - alpha)
            break
        case 3:
            startCoordinates = p4 * alpha + p1 * (1 - alpha)
            break
        default:
            break
        }
        
        return startCoordinates
    }
    
    func spawnIceCream() {
        if let _iceCreamNode = self.iceCreamNode {
            _iceCreamNode.removeFromParentNode()
        }
        var iceCreamPos: SCNVector3 = SCNVector3Zero
        repeat {
            iceCreamPos.x = Float.random(in: ((self.gameBoard.boundingBox.min.x + 0.03) ..< (self.gameBoard.boundingBox.max.x - 0.03)))
            iceCreamPos.y = Float.random(in: ((self.gameBoard.boundingBox.min.y + 0.03) ..< (self.gameBoard.boundingBox.max.y - 0.03)))
            iceCreamPos.z = 0.0
        } while(iceCreamPos.distance(vector: self.lastIceCreamPos) < 0.04)
        self.lastIceCreamPos = iceCreamPos
        
        let tmpIceCreamScene = SCNScene(named: "IceCone.dae")
        self.iceCreamNode = tmpIceCreamScene?.rootNode.childNode(withName: "IceCone", recursively: true)
        self.iceCreamNode.scale = SCNVector3Make(0.0018, 0.0018, 0.0018)
        
        self.iceCreamNode.position = iceCreamPos
        self.iceCreamNode.position.y += 0.02
        
        self.gameBoard.addChildNode(self.iceCreamNode)
    }
}
