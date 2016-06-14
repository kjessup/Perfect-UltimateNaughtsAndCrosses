//
//  GameState.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

let ultimateSlotCount = 3
let invalidId = -1

enum UltimateState {
	/// no game
	case None
	// waiting for opponent
	case Waiting
	// who won, current field
	case GameOver(PieceType, Field)
	// whose turn is it, required play board, current state
	case InPlay(PieceType, GridIndex, Field)
	// current player made invalid move
	case InvalidMove
	
	private enum UltimateStateId: Int {
		case NoneId, WaitingId, GameOverId, InPlayId, InvalidMoveId
	}
	
	private var serialId: Int {
		switch self {
		case .None:			return UltimateStateId.NoneId.rawValue
		case .Waiting:		return UltimateStateId.WaitingId.rawValue
		case .GameOver:		return UltimateStateId.GameOverId.rawValue
		case .InPlay:		return UltimateStateId.InPlayId.rawValue
		case .InvalidMove:	return UltimateStateId.InvalidMoveId.rawValue
		}
	}
	
	func serialize() -> String {
		switch self {
		case .None, .InvalidMove, .Waiting:
			return "\(self.serialId)"
		case .GameOver(let piece, let field):
			return "\(self.serialId)\(piece.serialize())\(field.serialize())"
		case .InPlay(let piece, let index, let field):
			return "\(self.serialId)\(piece.serialize())\(self.serialize(index))\(field.serialize())"
		}
	}
	
	func serialize(gridIndex: GridIndex) -> String {
		var s = ""
		if gridIndex.x == invalidId {
			s.appendContentsOf("-")
		} else {
			s.appendContentsOf("\(gridIndex.x)")
		}
		if gridIndex.y == invalidId {
			s.appendContentsOf("-")
		} else {
			s.appendContentsOf("\(gridIndex.y)")
		}
		return s
	}
	
	static func deserialize(idxX: String, idxY: String) -> GridIndex {
		let x = idxX[idxX.startIndex] == "-" ? invalidId : Int(idxX)!
		let y = idxY[idxY.startIndex] == "-" ? invalidId : Int(idxY)!
		return (x, y)
	}
	
	static func deserialize(source: String) -> UltimateState? {
		if let id = Int(String(source[source.startIndex])), stateId = UltimateStateId(rawValue: id) {
			switch stateId {
			case .NoneId:
				return .None
			case .WaitingId:
				return .Waiting
			case .GameOverId:
				if let pieceTypeInt = Int(String(source[source.startIndex.advancedBy(1)])),
					pieceType = PieceType(rawValue: pieceTypeInt) {
					
					let fieldString = source[source.startIndex.advancedBy(2)..<source.endIndex]
					if let field = Field.deserialize(fieldString) {
						return .GameOver(pieceType, field)
					}
				}
			case .InPlayId:
				if let pieceTypeInt = Int(String(source[source.startIndex.advancedBy(1)])),
					pieceType = PieceType(rawValue: pieceTypeInt) {
					
					let c1 = String(source[source.startIndex.advancedBy(2)])
					let c2 = String(source[source.startIndex.advancedBy(3)])
					
					let gridIndex = self.deserialize(c1, idxY: c2)
					
					let fieldString = source[source.startIndex.advancedBy(4)..<source.endIndex]
					if let field = Field.deserialize(fieldString) {
						return .InPlay(pieceType, gridIndex, field)
					}
				}
			case .InvalidMoveId:
				return .InvalidMove
			}
		}
		return nil
	}
}

enum AsyncResponse {
	case Error(Int, String)
	case SuccessEmpty()
	case SuccessInt(Int)
	case SuccessInt2(Int, Int)
	case SuccessString(String)
	case SuccessState(UltimateState)
}

protocol GameState {
	func createPlayer(nick: String, response: (AsyncResponse) -> ())
	func getPlayerNick(playerId: Int, response: (AsyncResponse) -> ())
	func getCurrentState(playerId: Int, response: (AsyncResponse) -> ())
	func getActiveGame(playerId: Int, response: (AsyncResponse) -> ())
	func playPieceOnBoard(playerId: Int, board: GridIndex, slotIndex: GridIndex, response: (AsyncResponse) -> ())
	func createGame(playerId: Int, gameType: PlayerType, response: (AsyncResponse) -> ())
}

