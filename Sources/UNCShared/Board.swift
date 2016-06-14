//
//  Board.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

struct Board: SquareGrid, Equatable, CustomStringConvertible {
	
	typealias Element = PieceType
	
	var slots: [[PieceType]]
	let owner: PieceType
	
	init(slots: [[PieceType]], owner: PieceType) {
		self.slots = slots
		self.owner = owner
	}
	
	subscript(index: GridIndex) -> Element {
		get {
			return self.slots[index.y][index.x]
		}
	}
	
	var description: String {
		return self.slots.map { $0.map { $0.description }.joinWithSeparator("") }.joinWithSeparator("\n")
	}
	
	func serialize() -> String {
		return self.slots.flatMap { $0 }.map { $0.serialize() }.joinWithSeparator("")
	}
	
	static func deserialize(source: String) -> Board? {
		let length = source.characters.count
		
		guard length == ultimateSlotCount * ultimateSlotCount else {
			return nil
		}
		
		var slots = [[PieceType]]()
		for segment in 0..<ultimateSlotCount {
			
			let startIndex = source.startIndex.advancedBy(segment * ultimateSlotCount)
			let endIndex = source.startIndex.advancedBy((segment+1) * ultimateSlotCount)
			
			let segment = source[startIndex..<endIndex]
			
			let subSlots = segment.characters.map { PieceType(rawValue: Int(String($0))!) ?? PieceType.None }
			slots.append(subSlots)
		}
		return Board(slots: slots, owner: sussOwner(slots))
	}
	
	private static func sussOwner(slots: [[PieceType]]) -> PieceType {
		// across
		for y in 0..<ultimateSlotCount {
			if let across = sameOwner(slots[y][0], two: slots[y][1], three: slots[y][2]) {
				return across
			}
		}
		// down
		for x in 0..<ultimateSlotCount {
			if let down = sameOwner(slots[0][x], two: slots[1][x], three: slots[2][x]) {
				return down
			}
		}
		// diag to right
		if let diagRight = sameOwner(slots[0][0], two: slots[1][1], three: slots[2][2]) {
			return diagRight
		}
		// diag to left
		if let diagLeft = sameOwner(slots[0][2], two: slots[1][1], three: slots[2][0]) {
			return diagLeft
		}
		return PieceType.None
	}
	
	private static func sameOwner(one: PieceType, two: PieceType, three: PieceType) -> PieceType? {
		if one != PieceType.None && one == two && one == three {
			return one
		}
		return nil
	}
}

func ==(lhs: Board, rhs: Board) -> Bool {
	return lhs.owner == rhs.owner && lhs.slots.flatMap { $0 } == rhs.slots.flatMap { $0 }
}

