import Foundation
import UIKit

class LoadingVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SoundController.shared().playSound(soundFileName: "game-background-music", loop: true, volume: 0.5)
        
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        _ = GameController.shared().setupGame()
    }
    
}
