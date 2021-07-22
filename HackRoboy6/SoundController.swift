import Foundation
import AVKit

class SoundController: NSObject, AVAudioPlayerDelegate {
    private static var sharedSoundController: SoundController = {
        let soundController = SoundController()
        
        // Configuration
        // ...
        
        return soundController
    }()
    
    // MARK: - Accessors
    
    class func shared() -> SoundController {
        return sharedSoundController
    }
    
    override init() {
        super.init()
        self.setupSoundController()
    }
    
    func setupSoundController() {
        
    }
    
    var players = [URL:AVAudioPlayer]()
    var duplicatePlayers = [AVAudioPlayer]()
    
    func playSound (soundFileName: String, loop: Bool = false, volume: Float = 1.0){
        
        let soundFileNameURL = URL(fileURLWithPath: Bundle.main.path(forResource: soundFileName, ofType: "mp3")!)
        
        if let player = players[soundFileNameURL] { //player for sound has been found
            
            if player.isPlaying == false { //player is not in use, so use that one
                player.prepareToPlay()
                player.play()
                
            } else { // player is in use, create a new, duplicate, player and use that instead
                
                let duplicatePlayer = try! AVAudioPlayer(contentsOf: soundFileNameURL)
                //use 'try!' because we know the URL worked before.
                
                duplicatePlayer.delegate = self
                //assign delegate for duplicatePlayer so delegate can remove the duplicate once it's stopped playing
                
                duplicatePlayers.append(duplicatePlayer)
                //add duplicate to array so it doesn't get removed from memory before finishing
                
                duplicatePlayer.prepareToPlay()
                duplicatePlayer.play()
                
            }
        } else { //player has not been found, create a new player with the URL if possible
            do{
                let player = try AVAudioPlayer(contentsOf: soundFileNameURL)
                players[soundFileNameURL] = player
                player.prepareToPlay()
                if(loop) {
                    player.numberOfLoops = 500
                }
                if(volume != 1.0) {
                    player.volume = volume
                }
                player.play()
            } catch {
                print("Could not play sound file!")
            }
        }
    }
    
    
    func playSounds(soundFileNames: [String]){
        
        for soundFileName in soundFileNames {
            playSound(soundFileName: soundFileName)
        }
    }
    
    func playSounds(soundFileNames: String...){
        for soundFileName in soundFileNames {
            playSound(soundFileName: soundFileName)
        }
    }
    
    func playSounds(soundFileNames: [String], withDelay: Double) { //withDelay is in seconds
        for (index, soundFileName) in soundFileNames.enumerated() {
            let delay = withDelay*Double(index)
            DispatchQueue.main.async {
                let _ = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(self.playSoundNotification(notification:)), userInfo: ["fileName":soundFileName], repeats: false)
            }
            
        }
    }
    
    @objc func playSoundNotification(notification: NSNotification) {
        if let soundFileName = notification.userInfo?["fileName"] as? String {
            playSound(soundFileName: soundFileName)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        duplicatePlayers.remove(at: duplicatePlayers.index(of: player)!)
        //Remove the duplicate player once it is done
    }
}
