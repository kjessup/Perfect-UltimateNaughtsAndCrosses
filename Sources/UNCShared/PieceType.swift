//
//  PieceType.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

public enum PieceType: Int, CustomStringConvertible {
	case none, ex, oh, exWin, ohWin, draw
	
	public var description: String {
		switch self {
		case .none:
			return "_"
		case .ex, exWin:
			return "X"
		case .oh, ohWin:
			return "O"
		case .draw:
			return "-"
		}
	}
	
	public var isWinner: Bool {
		switch self {
		case .exWin, .ohWin, .draw:
			return true
		default:
			return false
		}
	}
	
	public func serialize() -> String {
		return "\(self.rawValue)"
	}
	
	static func deserialize(source: String) -> PieceType? {
		if let intValue = Int(source) {
			return PieceType(rawValue: intValue)
		}
		return nil
	}
}
