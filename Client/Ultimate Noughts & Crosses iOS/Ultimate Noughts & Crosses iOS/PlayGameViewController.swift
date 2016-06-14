//
//  PlayGameViewController.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-04-26.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import UIKit

class PlayGameViewController: UIViewController {

	@IBOutlet weak var fieldStack: UIStackView!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var concedeButton: UIButton!
	
	var requiredBoard: GridIndex?
	var myPiece = PieceType.None
	var gameOn = false
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		self.initializeField()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		let gameState = GameStateClient()
		if let playerId = gameState.savedPlayerId {
			gameState.getActiveGame(playerId) {
				responseValue in
				
				if case .SuccessInt2(_, let pieceType) = responseValue {
					self.myPiece = PieceType(rawValue: pieceType)!
					self.gameOn = true
					self.updateCurrentState()
				}
			}
		}
    }

	func initializeField() {
		for boardY in 0..<ultimateSlotCount {
			for boardX in 0..<ultimateSlotCount {
				
				if let board = self.getBoardStack((boardX, boardY)) {
					
					for tileY in 0..<ultimateSlotCount {
						for tileX in 0..<ultimateSlotCount {
							
							if let tile = self.getBoardTile(board, index: (tileX, tileY)) {
								
								let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PlayGameViewController.tileTapped))
								tile.addGestureRecognizer(tapGesture)
								let currLocation = ((x:boardX, y:boardY), (x:tileX, y:tileY))
								tile.taggedLocation = currLocation
							}
						}
					}
				}
			}
		}
	}
	
	@IBAction func concedeGame() {
		if self.gameOn {
			let gameState = GameStateClient()
			gameState.concedeGame {
				responseValue in
				
				dispatch_async(dispatch_get_main_queue()) {
					if case .SuccessState(let state) = responseValue {
						self.updateCurrentState(state)
					} else {
						
					}
				}
			}
		} else {
			self.dismissViewControllerAnimated(true) {}
		}
	}
	
	func tileTapped(tapGesture: UITapGestureRecognizer) {
		guard self.gameOn else {
			return
		}
		
		if let tile = tapGesture.view {
			let (board, tile) = tile.taggedLocation
			
			let gameState = GameStateClient()
			gameState.playPieceOnBoard(gameState.savedPlayerId!, board: board, slotIndex: tile) {
				responseValue in
				
				dispatch_async(dispatch_get_main_queue()) {
					if case .SuccessState(let state) = responseValue {
						self.updateCurrentState(state)
					} else {
						
					}
				}
			}
		}
	}
	
	func getBoardStack(index: GridIndex) -> UIStackView? {
		let subViews1 = self.fieldStack.arrangedSubviews
		guard subViews1.count >= index.y else {
			return nil
		}
		guard let subStack1 = subViews1[index.y] as? UIStackView else {
			return nil
		}
		
		let subViews2 = subStack1.arrangedSubviews
		guard subViews2.count >= index.x else {
			return nil
		}
		guard let subStack2 = subViews2[index.x] as? UIStackView else {
			return nil
		}
		
		return subStack2
	}
	
	func getBoardTile(board: UIStackView, index: GridIndex) -> UIImageView? {
		let subViews1 = board.arrangedSubviews
		guard subViews1.count >= index.y else {
			return nil
		}
		guard let subStack1 = subViews1[index.y] as? UIStackView else {
			return nil
		}
		
		let subViews2 = subStack1.arrangedSubviews
		guard subViews2.count >= index.x else {
			return nil
		}
		
		let subStack2 = subViews2[index.x]
		return subStack2 as? UIImageView
	}
	
	func updateCurrentState() {
		self.fetchCurrentState {
			state in
			
			if let state = state {
				dispatch_async(dispatch_get_main_queue()) {
					self.updateCurrentState(state)
				}
			}
		}
	}
	
	func fetchCurrentState(callback: (UltimateState?) -> ()) {
		let gameState = GameStateClient()
		gameState.getCurrentState(gameState.savedPlayerId!) {
			responseValue in
			
			if case .SuccessState(let state) = responseValue {
				callback(state)
			}
		}
	}
	
	func updateField(field: Field, activeBoard: GridIndex) {
		
		let haveActiveBoard = activeBoard != (invalidId, invalidId)
		
		for boardY in 0..<ultimateSlotCount {
			for boardX in 0..<ultimateSlotCount {
				
				let boardIndex = (boardX, boardY)
				if let boardView = self.getBoardStack(boardIndex) {
					
					let board = field[boardIndex]
					if board.owner != .None {
						boardView.alpha = 0.4
						if boardView.arrangedSubviews.count > 1 {
							
							let subViews = boardView.arrangedSubviews
							subViews.forEach { $0.removeFromSuperview() }
							
							let imageView = UIImageView(frame: boardView.bounds)
							boardView.addArrangedSubview(imageView)
							if board.owner == .Ex {
								imageView.image = UIImage(named: "Ex")
							} else {
								imageView.image = UIImage(named: "Oh")
							}
						}
					} else if !haveActiveBoard || boardIndex == activeBoard {
						boardView.alpha = 1.0
					} else {
						boardView.alpha = 0.4
					}
					
					if board.owner != .None {
						continue
					}
					
					for slotY in 0..<ultimateSlotCount {
						for slotX in 0..<ultimateSlotCount {
							
							let slotIndex = (slotX, slotY)
							if let slotView = self.getBoardTile(boardView, index: slotIndex) {
								
								let slot = board[slotIndex]
								if case .Ex = slot {
									slotView.image = UIImage(named: "Ex")
								} else if case .Oh = slot {
									slotView.image = UIImage(named: "Oh")
								}
							}
						}
					}
				}
			}
		}
	}
	
	func updateCurrentState(state: UltimateState) {
		switch state {
		case .GameOver(let winningPiece, let field):
			self.updateField(field, activeBoard: (invalidId, invalidId))
			if winningPiece == .Draw {
				self.statusLabel.text = "The game was a draw!"
			} else if winningPiece == (self.myPiece == .Ex ? .ExWin : .OhWin) {
				self.statusLabel.text = "You won!"
			} else {
				self.statusLabel.text = "You lost!"
			}
			self.gameOn = false
			self.concedeButton.setTitle("Main Menu", forState: .Normal)
		case .InPlay(let turnPiece, let board, let field):
			self.updateField(field, activeBoard: board)
			if turnPiece == self.myPiece {
				self.statusLabel.text = "It is your move."
			} else {
				self.statusLabel.text = "Opponent's move…"
				self.queueStatusCheck()
			}
		case .InvalidMove:
			self.statusLabel.text = "You made an invalid move."
		case .Waiting:
			self.statusLabel.text = "Opponent's move…"
		case .None:
			()
		}
	}
	
	func queueStatusCheck() {
		guard self.gameOn else {
			return
		}
		
		let timeAfter = dispatch_time(0, Int64(NSEC_PER_SEC))
		dispatch_after(timeAfter, dispatch_get_main_queue()) { [weak self] in
			self?.updateCurrentState()
		}
	}
	
}
