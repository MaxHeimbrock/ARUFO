
import CoreLocation
import AVFoundation
import ARKit
import Vision
import SceneKit

class GameController {
    
    private static var sharedGameController: GameController = {
        let gameController = GameController()
        
        // Configuration
        // ...
        
        return gameController
    }()
    
    // MARK: - Accessors
    
    class func shared() -> GameController {
        return sharedGameController
    }
    
    enum GameStatus: Int {
        case LOADING = 0
        case PLAYING = 1
        case WIN = 2
        case LOOSE = 3
    }
    var gameStatus: GameStatus = GameStatus.LOADING
    
    struct SoundLibrary {
        let applause: String = "applause-3.mp3"
        let ambient: String = "large_crowd_ambient.mp3"
        let ambientFunk: String = "game-background-music.mp3"
    }
    
    struct PlayerData {
        var lives: Int = 3
        var collected: Int = 0
        var difficulty: Int = 0
        var time: Int = 0
    }
    var playerData: PlayerData = PlayerData(lives: 3, collected: 0, difficulty: 0, time: 0)
    
    // MARK: - Views
    var gameView: GameVC!
    
    var openCVWrapper: OpenCVWrapper = OpenCVWrapper()
    
    var fixedUpdateTimer: Timer = Timer()
    var updateTimerValue: Double = 0
    
    init() {
        //self.setupGame()
    }
    
    func setupGame() {
        // Instantiate Default Views
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        self.gameView = (mainStoryboard.instantiateViewController(withIdentifier: "GameVC") as! GameVC)
        UIApplication.shared.keyWindow?.rootViewController = self.gameView
        
        self.playerData = PlayerData(lives: 3, collected: 0, difficulty: 0, time: 0)
        
        self.startGame()
        self.gameView.spawnIceCream()
    }
    
    
    var soundCooldownActive = false
    var soundCooldownActive2 = false
    var soundCooldownActive3 = false
    /// Fixed Update every 0.25 seconds for additional game logic
    @objc func fixedUpdate() {
        updateTimerValue += 0.25
        
        if(self.gameStatus == GameStatus.LOOSE) {
            UIApplication.shared.keyWindow?.rootViewController =  (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LostGameVC") as! LostGameVC)
            self.fixedUpdateTimer.invalidate()
            return
        }
        if(self.gameStatus == GameStatus.WIN) {
            UIApplication.shared.keyWindow?.rootViewController =  (UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WonGameVC") as! WonGameVC)
            self.fixedUpdateTimer.invalidate()
            return
        }
        
        if(self.gameStatus == GameStatus.PLAYING && updateTimerValue.truncatingRemainder(dividingBy: (Double(3 - self.playerData.difficulty / 2))) == 0) {
            self.gameView.spawnEnemy()
        }
        
        // Collision Detection (IceCream - Player)
        if(self.gameView.iceCreamNode != nil) {
            let p1p2 = (self.gameView.iceCreamNode.worldPosition - self.gameView.roboyNode.position).magnitude
            let r1r2 = 0.005 + 0.013
            if(Double(p1p2) < r1r2) {
                self.gameView.iceCreamNode.removeFromParentNode()
                self.playerData.collected += 1
                self.gameView.uiCollectedNodes.removeFromParentNode()
                self.gameView.uiCollectedNodes = self.gameView.createTextNode(string: "Ice: \(self.playerData.collected)/15", pos: SCNVector3Make(-0.030, 0.0168, -0.06))
                self.gameView.sceneView.scene.rootNode.addChildNode(self.gameView.uiCollectedNodes)
                
                if(self.playerData.collected % 5 == 0) {
                    self.playerData.difficulty += 1
                    if(self.playerData.difficulty > 2) {
                        self.gameStatus = GameStatus.WIN
                    } else {
                        SoundController.shared().playSound(soundFileName: "oh-jeah-01")
                        self.gameView.spawnIceCream()
                        
                    }
                    return
                }
                
                // Play Sound
                if(!soundCooldownActive3) {
                    SoundController.shared().playSound(soundFileName: "yummy")
                    soundCooldownActive3 = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.soundCooldownActive3 = false
                    }
                }
                self.gameView.spawnIceCream()
            }
        }
        
        // Collision Detection (Enemy - Player)
        for (index, enemy) in self.gameView.enemyNodes.enumerated() {
            let p1p2 = (enemy.worldPosition - self.gameView.roboyNode.position).magnitude
            let r1r2 = 0.005 + 0.013
            
            if(Double(p1p2) < r1r2) {
                // Remove Node
                enemy.removeFromParentNode()
                self.gameView.enemyNodes.remove(at: index)
                
                // Decrease Lives
                self.playerData.lives -= 1
                self.gameView.uiLivesNodes.removeFromParentNode()
                self.gameView.uiLivesNodes = self.gameView.createTextNode(string: "Lives: \(self.playerData.lives)", pos: SCNVector3Make(0.012, 0.0168, -0.06))
                self.gameView.sceneView.scene.rootNode.addChildNode(self.gameView.uiLivesNodes)
                
                if(self.playerData.lives <= 0) {
                    self.gameStatus = GameStatus.LOOSE
                    return
                }
                
                // Play Sound
                if(!soundCooldownActive2) {
                    SoundController.shared().playSound(soundFileName: "god-damn-it")
                    soundCooldownActive2 = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        self.soundCooldownActive2 = false
                    }
                }
            } else {
                if(Double(p1p2) - r1r2 < 0.025) {
                    if(!soundCooldownActive) {
                        SoundController.shared().playSound(soundFileName: "ohh-walla", volume: 0.7)
                        soundCooldownActive = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                            self.soundCooldownActive = false
                        }
                    }
                }
            }
        }
    }
    
    func startGame() {
        self.gameStatus = GameStatus.PLAYING
        
        //SoundController.shared().playSound(soundFileName: "game-background-music", loop: true, volume: 0.5)
        SoundController.shared().playSound(soundFileName: "large_crowd_ambient", loop: true, volume: 0.5)
        
        DispatchQueue.main.async {
            // Setup Timer
            self.fixedUpdateTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(self.fixedUpdate), userInfo: nil, repeats: true)
        }
    }
}
