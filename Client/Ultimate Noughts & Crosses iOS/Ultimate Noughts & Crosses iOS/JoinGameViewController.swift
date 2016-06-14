//
//  JoinGameViewController.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-04-26.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import UIKit

class JoinGameViewController: UIViewController {

	var waiting = false
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		let gameState = GameStateClient()
		if let playerId = gameState.savedPlayerId {
			gameState.createGame(playerId, gameType: PlayerType.MultiPlayer) {
				response in
				
				dispatch_async(dispatch_get_main_queue()) {
					
					if case .SuccessInt(let gameId) = response {
						
						if gameId != invalidId {
							self.dismissViewControllerAnimated(true) {}
						} else {
							self.startWaiting()
						}
						
					} else if case .Error(let code, let msg) = response {
						
						let alert = UIAlertController(title: "Error Starting Game", message: "\(msg) (\(code))", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in self.dismissViewControllerAnimated(true) {} }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }
						
					} else {
						
						let alert = UIAlertController(title: "Error Starting Game", message: "Unexpected response type \(response)", preferredStyle: .Alert)
						let action = UIAlertAction(title: "OK", style: .Default) { _ in self.dismissViewControllerAnimated(true) {} }
						alert.addAction(action)
						self.presentViewController(alert, animated: true) { }
					}
				}
			}
		}
	}
	
	@IBAction func stopWaiting() {
		let gameState = GameStateClient()
		gameState.concedeGame {
			response in
			
			dispatch_async(dispatch_get_main_queue()) {
				self.dismissViewControllerAnimated(true) {}
			}
		}
	}
	
	func startWaiting() {
		self.waiting = true
		self.checkStatus()
	}
	
	func checkStatus() {
		guard self.waiting else {
			return
		}
		
		let gameState = GameStateClient()
		if let playerId = gameState.savedPlayerId {
			gameState.getActiveGame(playerId) { [weak self]
				response in
				
				guard let me = self else {
					return
				}
				
				if case .SuccessInt2(let gameId, _) = response where gameId != invalidId {
					me.waiting = false
					dispatch_async(dispatch_get_main_queue()) {
						me.dismissViewControllerAnimated(true) {}
					}
				} else {
					me.queueStatusCheck()
				}
			}
		}
	}
	
	func queueStatusCheck() {
		guard self.waiting else {
			return
		}
		
		let timeAfter = dispatch_time(0, Int64(NSEC_PER_SEC))
		dispatch_after(timeAfter, dispatch_get_main_queue()) { [weak self] in
			self?.checkStatus()
		}
	}
}
