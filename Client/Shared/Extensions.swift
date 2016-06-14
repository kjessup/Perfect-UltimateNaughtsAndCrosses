//
//  Extensions.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-05-01.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import UIKit

extension UIView {
	
	// store the GridIndexes in the tag one value for each octal
	// returns (Board index, Slot index)
	var taggedLocation: (GridIndex, GridIndex) {
		get {
			let tag = self.tag
			let boardX = (tag & 0xFF000000) >> 24,
				boardY = (tag & 0xFF0000) >> 16
			let slotX = (tag & 0xFF00) >> 8,
				slotY = tag & 0xFF
			
			return ((boardX, boardY), (slotX, slotY))
		}
		set {
			let tag = (newValue.0.x << 24)
				| (newValue.0.y << 16)
				| (newValue.1.x << 8)
				| newValue.1.y
			self.tag = tag
		}
	}
}