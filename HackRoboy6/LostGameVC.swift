import Foundation
import UIKit

class LostGameVC: UIViewController {
    
    @IBOutlet var restartGame: UIButton!
    
    @IBAction func restartButtonTapped(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        
        UIApplication.shared.keyWindow?.rootViewController = (mainStoryboard.instantiateViewController(withIdentifier: "LoadingVC") as! LoadingVC)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SoundController.shared().playSound(soundFileName: "game-over")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            SoundController.shared().playSound(soundFileName: "oh-no")
        }
    }
}
