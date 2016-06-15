//
//  Grid.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

// X,Y
// Across, Down
//  _________________
// | 0,0 | 1,0 | 2,0 |
// |_________________|
// | 0,1 | 1,1 | 2,1 |
// |_________________|
// | 0,2 | 1,2 | 2,2 |
//  -----------------

public typealias GridIndex = (x: Int, y: Int)

public protocol SquareGrid {
	associatedtype Element
	
	// slots are indexed as [y][x]
	var slots: [[Element]] { get }
	
	subscript(index: GridIndex) -> Element { get }
}
