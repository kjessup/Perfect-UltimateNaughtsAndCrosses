//
//  EndPoint-Client.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-04-26.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import Foundation

extension EndPoint {
	func replace(variables variables: [String]?) -> String {
		if var replacements = variables {
			return self.rawValue.characters.split("/").map {
					$0[$0.startIndex] != "{" ? String($0) : replacements.removeFirst().stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
				}.joinWithSeparator("/")
		}
		return self.rawValue
	}
}
