//
//  Board.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

public struct Board: SquareGrid, Equatable, CustomStringConvertible {
	
	public typealias Element = PieceType
	
	public var slots: [[PieceType]]
	let owner: PieceType
	
	public init(slots: [[PieceType]], owner: PieceType) {
		self.slots = slots
		self.owner = owner
	}
	
	public subscript(index: GridIndex) -> Element {
		get {
			return self.slots[index.y][index.x]
		}
	}
	
	public var description: String {
		return self.slots.map { $0.map { $0.description }.joined(separator: "") }.joined(separator: "\n")
	}
	
	func serialize() -> String {
		return self.slots.flatMap { $0 }.map { $0.serialize() }.joined(separator: "")
	}
	
	static func deserialize(source: String) -> Board? {
		let length = source.characters.count
		
		guard length == ultimateSlotCount * ultimateSlotCount else {
			return nil
		}
		
		var slots = [[PieceType]]()
		for segment in 0..<ultimateSlotCount {
			let startIndex = source.index(source.startIndex, offsetBy: segment * ultimateSlotCount)
			let endIndex = source.index(source.startIndex, offsetBy: (segment+1) * ultimateSlotCount)
			let segment = source[startIndex..<endIndex]
			let subSlots = segment.characters.map { PieceType(rawValue: Int(String($0))!) ?? PieceType.none }
			slots.append(subSlots)
		}
		return Board(slots: slots, owner: sussOwner(slots: slots))
	}
	
	private static func sussOwner(slots: [[PieceType]]) -> PieceType {
		// across
		for y in 0..<ultimateSlotCount {
			if let across = sameOwner(one: slots[y][0], two: slots[y][1], three: slots[y][2]) {
				return across
			}
		}
		// down
		for x in 0..<ultimateSlotCount {
			if let down = sameOwner(one: slots[0][x], two: slots[1][x], three: slots[2][x]) {
				return down
			}
		}
		// diag to right
		if let diagRight = sameOwner(one: slots[0][0], two: slots[1][1], three: slots[2][2]) {
			return diagRight
		}
		// diag to left
		if let diagLeft = sameOwner(one: slots[0][2], two: slots[1][1], three: slots[2][0]) {
			return diagLeft
		}
		return PieceType.none
	}
	
	private static func sameOwner(one: PieceType, two: PieceType, three: PieceType) -> PieceType? {
		if one != PieceType.none && one == two && one == three {
			return one
		}
		return nil
	}
}

public func ==(lhs: Board, rhs: Board) -> Bool {
	return lhs.owner == rhs.owner && lhs.slots.flatMap { $0 } == rhs.slots.flatMap { $0 }
}

