//
//  MainMenuViewController.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-04-28.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import UIKit

let playGameSegue = "playGame"
let joinGameSegue = "joinGame"

class MainMenuViewController: UIViewController {

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

        let gameState = GameStateClient()
		if let playerId = gameState.savedPlayerId {
			gameState.getActiveGame(playerId) {
				responseValue in
				
				if case .SuccessInt2(let gameId, _) = responseValue {
					if gameId != invalidId {
						// let's continue playing
						dispatch_async(dispatch_get_main_queue()) {
							self.performSegueWithIdentifier(playGameSegue, sender: nil)
						}
					} else {
						
					}
				} else {
					
				}
			}
		}
    }
	
	@IBAction func joinGame() {
		self.performSegueWithIdentifier(joinGameSegue, sender: nil)
	}
	
	@IBAction func botGame() {
		let gs = GameStateClient()
		if let playerId = gs.savedPlayerId {
		
			gs.createGame(playerId, gameType: PlayerType.Bot) {
				response in
				
				dispatch_async(dispatch_get_main_queue()) {
					
					if case .SuccessInt(_) = response {
						self.performSegueWithIdentifier(playGameSegue, sender: nil)
					} else if case .Error(let code, let msg) = response {
						
						let alert = UIAlertController(title: "Error Starting Game", message: "\(msg) (\(code))", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }
						
					} else {
						
						let alert = UIAlertController(title: "Error Starting Game", message: "Unexpected response type \(response)", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }
					}
				}
			}
		}
	}
}
