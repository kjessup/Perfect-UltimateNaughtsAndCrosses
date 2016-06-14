//
//  PieceType.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

enum PieceType: Int, CustomStringConvertible {
	case None, Ex, Oh, ExWin, OhWin, Draw
	
	var description: String {
		switch self {
		case .None:
			return "_"
		case .Ex, ExWin:
			return "X"
		case .Oh, OhWin:
			return "O"
		case .Draw:
			return "-"
		}
	}
	
	var isWinner: Bool {
		switch self {
		case .ExWin, .OhWin, .Draw:
			return true
		default:
			return false
		}
	}
	
	func serialize() -> String {
		return "\(self.rawValue)"
	}
	
	static func deserialize(source: String) -> PieceType? {
		if let intValue = Int(source) {
			return PieceType(rawValue: intValue)
		}
		return nil
	}
}
