//
//  RegisterNickViewController.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-04-26.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import UIKit

let nickRegisteredSegue = "nickRegistered"

class RegisterNickViewController: UIViewController {

	@IBOutlet weak var nickText: UITextField!
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		var gameState = GameStateClient()
		if let playerId = gameState.savedPlayerId {
			// validate it
			gameState.getPlayerNick(playerId) {
				response in
				
				dispatch_async(dispatch_get_main_queue()) {
					if case .SuccessString(let nick) = response {
						GameStateClient.retrievedPlayerNick = nick
						self.performSegueWithIdentifier(nickRegisteredSegue, sender: nil)
					} else if case .Error(-1004, let msg) = response {
						
						let alert = UIAlertController(title: "Error Contacting Server", message: "\(msg) (-1004)", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }
						
					} else {
						// player id was not valid. reset it
						gameState.savedPlayerId = nil
					}
				}
			}
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func registerNick() {
		if let nickText = self.nickText.text where !nickText.isEmpty{
			var gameState = GameStateClient()
			
			gameState.createPlayer(nickText) {
				response in
				
				dispatch_async(dispatch_get_main_queue()) {
					
					if case .SuccessInt(let playerId) = response {
						gameState.savedPlayerId = playerId
						self.performSegueWithIdentifier(nickRegisteredSegue, sender: nil)
					} else if case .Error(let code, let msg) = response {
						
						let alert = UIAlertController(title: "Error registering nick", message: "\(msg) (\(code))", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }
						
					} else {
						
						let alert = UIAlertController(title: "Error registering nick", message: "Unexpected response type \(response)", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }						
					}
				}
			}
		}
	}
}
