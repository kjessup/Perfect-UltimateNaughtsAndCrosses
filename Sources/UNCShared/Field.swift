//
//  Field.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

struct Field: SquareGrid, Equatable, CustomStringConvertible {
	
	typealias Element = Board
	
	var slots: [[Board]]
	
	init(slots: [[Board]]) {
		self.slots = slots
	}
	
	subscript(index: GridIndex) -> Element {
		get {
			return self.slots[index.y][index.x]
		}
	}
	
	func serialize() -> String {
		return self.slots.flatMap { $0 }.map { $0.serialize() }.joinWithSeparator("")
	}
	
	static func deserialize(source: String) -> Field? {
		let length = source.characters.count
		
		guard length == ultimateSlotCount * ultimateSlotCount * ultimateSlotCount * ultimateSlotCount else {
			return nil
		}
		var slots = [[Board]]()
		var subSlots = [Board]()
		for segment in 0..<(ultimateSlotCount * ultimateSlotCount) {
			
			let startIndex = source.startIndex.advancedBy(segment * ultimateSlotCount * ultimateSlotCount)
			let endIndex = source.startIndex.advancedBy((segment+1) * ultimateSlotCount * ultimateSlotCount)
			
			let segment = source[startIndex..<endIndex]
			guard let board = Board.deserialize(segment) else {
				return nil
			}
			subSlots.append(board)
			if subSlots.count == ultimateSlotCount {
				slots.append(subSlots)
				subSlots = [Board]()
			}
		}
		return Field(slots: slots)
	}
	
	var description: String {
		var s = ""
		
		for _ in 0..<(ultimateSlotCount * ultimateSlotCount + 10) {
			s.appendContentsOf("_")
		}
		s.appendContentsOf("\n")
		
		for y in 0..<ultimateSlotCount {
			
			let boards = [self[(0, y)], self[(1, y)], self[(2, y)]]
			
			for rowY in 0..<ultimateSlotCount { // each row
				s.appendContentsOf("| ")
				for boardY in 0..<ultimateSlotCount { // each board
					if boardY != 0 {
						s.appendContentsOf(" | ")
					}
					for boardX in 0..<ultimateSlotCount { // each x in each board
						s.appendContentsOf("\(boards[boardY][(boardX, rowY)])")
					}
				}
				s.appendContentsOf(" |\n")
			}
			
			for _ in 0..<(ultimateSlotCount * ultimateSlotCount + 10) {
				s.appendContentsOf("_")
			}
			s.appendContentsOf("\n")
		}
		return s
	}
}

func ==(lhs: Field, rhs: Field) -> Bool {
	return lhs.slots.flatMap { $0 } == rhs.slots.flatMap { $0 }
}


