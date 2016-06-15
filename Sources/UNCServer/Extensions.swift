//
//  Extensions.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-24.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import PerfectLib
import UNCShared

extension WebResponse {
	func badRequest(msg: String) {
		self.setStatus(code: 400, message: "Bad Request")
        self.appendBody(string: msg)
	}
	
	var playerId: Int? {
		get {
			return self.request.playerId
		}
		set {
			let expiresIn = newValue == nil ? -500.0 : 2000000000.0
			let cookie = Cookie(name: playerIdCookieName, value: String(newValue), domain: nil, expires: nil, expiresIn: expiresIn, path: "/", secure: false, httpOnly: false)
			self.addCookie(cookie)
		}
	}
}

extension WebRequest {
	var playerId: Int? {
		for (name, value) in self.cookies {
			if name == playerIdCookieName {
				if let playerId = Int(value) {
					return playerId
				}
			}
		}
		return nil
	}
}

