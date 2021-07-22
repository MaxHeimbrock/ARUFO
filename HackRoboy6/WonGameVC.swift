import Foundation
import UIKit

class WonGameVC: UIViewController {
    
    @IBAction func restartButtonTapped(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        
        UIApplication.shared.keyWindow?.rootViewController = (mainStoryboard.instantiateViewController(withIdentifier: "LoadingVC") as! LoadingVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SoundController.shared().playSound(soundFileName: "oh-yeah")
    }
}
