//
//  Field.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

public struct Field: SquareGrid, Equatable, CustomStringConvertible {
	
	public typealias Element = Board
	
	public var slots: [[Board]]
	
	public init(slots: [[Board]]) {
		self.slots = slots
	}
	
	public subscript(index: GridIndex) -> Element {
		get {
			return self.slots[index.y][index.x]
		}
	}
	
	public func serialize() -> String {
		return self.slots.flatMap { $0 }.map { $0.serialize() }.joined(separator: "")
	}
	
	public static func deserialize(source: String) -> Field? {
		let length = source.characters.count
		
		guard length == ultimateSlotCount * ultimateSlotCount * ultimateSlotCount * ultimateSlotCount else {
			return nil
		}
		var slots = [[Board]]()
		var subSlots = [Board]()
		for segment in 0..<(ultimateSlotCount * ultimateSlotCount) {
			
			let startIndex = source.index(source.startIndex, offsetBy: segment * ultimateSlotCount * ultimateSlotCount)
			let endIndex = source.index(source.startIndex, offsetBy: (segment+1) * ultimateSlotCount * ultimateSlotCount)
			
			let segment = source[startIndex..<endIndex]
			guard let board = Board.deserialize(source: segment) else {
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
	
	public var description: String {
		var s = ""
		
		for _ in 0..<(ultimateSlotCount * ultimateSlotCount + 10) {
			s.append("_")
		}
		s.append("\n")
		
		for y in 0..<ultimateSlotCount {
			
			let boards = [self[(0, y)], self[(1, y)], self[(2, y)]]
			
			for rowY in 0..<ultimateSlotCount { // each row
				s.append("| ")
				for boardY in 0..<ultimateSlotCount { // each board
					if boardY != 0 {
						s.append(" | ")
					}
					for boardX in 0..<ultimateSlotCount { // each x in each board
						s.append("\(boards[boardY][(boardX, rowY)])")
					}
				}
				s.append(" |\n")
			}
			
			for _ in 0..<(ultimateSlotCount * ultimateSlotCount + 10) {
				s.append("_")
			}
			s.append("\n")
		}
		return s
	}
}

public func ==(lhs: Field, rhs: Field) -> Bool {
	return lhs.slots.flatMap { $0 } == rhs.slots.flatMap { $0 }
}


