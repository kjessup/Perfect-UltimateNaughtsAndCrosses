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
import UNCShared

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
		let (_, _, x, y) = gameState.getCurrentPlayer(gameId: self.gameId)
		if x != invalidId {
			let boardId = gameState.getBoardId(gameId: gameId, index: (x, y))
			return self.makeMoveOnBoard(gameState: gameState, boardId: boardId)
		}
		// we can move on any board
		// pick an unowned board at random
		var boards = [Int]()
		for x in 0..<3 {
			for y in 0..<3 {
				let boardId = gameState.getBoardId(gameId: self.gameId, index: (x, y))
				let boardOwner = gameState.getBoardOwner(boardId: boardId)
				if boardOwner == .none {
					boards.append(boardId)
				}
			}
		}
		guard boards.count > 0 else {
			fatalError("It's my turn but there are no valid boards on which to play")
		}
		let rnd = randomInt(max: boards.count)
		let boardId = boards[Int(rnd)]
		self.makeMoveOnBoard(gameState: gameState, boardId: boardId)
	}
	
	private func makeMoveOnBoard(gameState: GameStateServer, boardId: Int) {
		// find a random slot
		var slots = [(Int, GridIndex)]()
		for x in 0..<3 {
			for y in 0..<3 {
				let slotId = gameState.getSlotId(boardId: boardId, index: (x, y))
				let slotOwner = gameState.getSlotOwner(slotId: slotId)
				if slotOwner == .none {
					slots.append((slotId, (x, y)))
				}
			}
		}
		guard slots.count > 0 else {
			fatalError("It's my turn but there are no valid slots on which to play")
		}
		let rnd = randomInt(max: slots.count)
		let slotId = slots[Int(rnd)]
		let _ = gameState.setSlotOwner(slotId: slotId.0, type: self.piece)
		let _ = gameState.getBoardOwner(boardId: boardId)
		let _ = gameState.endTurn(gameId: self.gameId)
		
		do {
			let boardId = gameState.getBoardId(gameId: gameId, index: slotId.1)
			let boardOwner = gameState.getBoardOwner(boardId: boardId)
			if boardOwner == .none {
				gameState.setActiveBoard(gameId: gameId, index: slotId.1)
			} else {
				gameState.setActiveBoard(gameId: gameId, index: (invalidId, invalidId))
			}
		}
	}
}

