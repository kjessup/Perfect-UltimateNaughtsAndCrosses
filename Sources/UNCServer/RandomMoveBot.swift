//
//  PlayerBot.swift
//  Ultimate Noughts and Crosses
//
//  Created by Kyle Jessup on 2015-11-16.
//  Copyright © 2015 PerfectlySoft. All rights reserved.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

#if os(Linux)
	
import SwiftGlibc

func randomInt(max: Int) -> Int {
	return Int(random() % (max + 1))
}
	
#else
	
import Darwin

func randomInt(max: Int) -> Int {
	return Int(arc4random_uniform(UInt32(max)))
}
	
#endif

struct RandomMoveBot {
	
	let nick: String
	let gameId: Int
	let piece: PieceType
	
	init(gameId: Int, piece: PieceType) {
		self.init(nick: "Random-Bot", gameId: gameId, piece: piece)
	}

	init(nick: String, gameId: Int, piece: PieceType) {
		self.nick = nick
		self.gameId = gameId
		self.piece = piece
	}
	
	func makeMove(gameState: GameStateServer) {
		let (_, _, x, y) = gameState.getCurrentPlayer(self.gameId)
		if x != invalidId {
			let boardId = gameState.getBoardId(gameId, index: (x, y))
			return self.makeMoveOnBoard(gameState, boardId: boardId)
		}
		// we can move on any board
		// pick an unowned board at random
		var boards = [Int]()
		for x in 0..<3 {
			for y in 0..<3 {
				let boardId = gameState.getBoardId(self.gameId, index: (x, y))
				let boardOwner = gameState.getBoardOwner(boardId)
				if boardOwner == .None {
					boards.append(boardId)
				}
			}
		}
		guard boards.count > 0 else {
			fatalError("It's my turn but there are no valid boards on which to play")
		}
		let rnd = randomInt(boards.count)
		let boardId = boards[Int(rnd)]
		self.makeMoveOnBoard(gameState, boardId: boardId)
	}
	
	private func makeMoveOnBoard(gameState: GameStateServer, boardId: Int) {
		// find a random slot
		var slots = [(Int, GridIndex)]()
		for x in 0..<3 {
			for y in 0..<3 {
				let slotId = gameState.getSlotId(boardId, index: (x, y))
				let slotOwner = gameState.getSlotOwner(slotId)
				if slotOwner == .None {
					slots.append((slotId, (x, y)))
				}
			}
		}
		guard slots.count > 0 else {
			fatalError("It's my turn but there are no valid slots on which to play")
		}
		let rnd = randomInt(slots.count)
		let slotId = slots[Int(rnd)]
		gameState.setSlotOwner(slotId.0, type: self.piece)
		let _ = gameState.getBoardOwner(boardId)
		gameState.endTurn(self.gameId)
		
		do {
			let boardId = gameState.getBoardId(gameId, index: slotId.1)
			let boardOwner = gameState.getBoardOwner(boardId)
			if boardOwner == .None {
				gameState.setActiveBoard(gameId, index: slotId.1)
			} else {
				gameState.setActiveBoard(gameId, index: (invalidId, invalidId))
			}
		}
	}
}

