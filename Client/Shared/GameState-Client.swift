//
//  UltimateState-Client.swift
//  Ultimate Noughts & Crosses iOS
//
//  Created by Kyle Jessup on 2016-04-25.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import Foundation

let requestRoot = "http://127.0.0.1:8181/"
//let requestRoot = "http://10.10.1.121:8181/"
let savedPlayerIdKey = "unc.saved.uid"

struct GameStateClient: GameState {
	
	static var retrievedPlayerNick: String?
	
	let session = NSURLSession.sharedSession()
	
	var savedPlayerId: Int? {
		get {
			if let playerId = NSUserDefaults.standardUserDefaults().valueForKey(savedPlayerIdKey) {
				return playerId as? Int
			}
			return nil
		}
		set(to) {
			let defaults = NSUserDefaults.standardUserDefaults()
			if let playerId = to {
				defaults.setValue(playerId, forKey: savedPlayerIdKey)
			} else {
				defaults.removeObjectForKey(savedPlayerIdKey)
			}
			defaults.synchronize()
		}
	}
	
	func createPlayer(nick: String, response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.RegisterNick, args: [nick])
		self.performRequest(request) {
			responseValue in
			
			switch responseValue {
			case .SuccessString(let str):
				if let validId = Int(str) {
					response(.SuccessInt(validId))
				} else {
					response(.Error(-1, "Invalid response from server: \(str)"))
				}
			default:
				response(responseValue)
			}
		}
	}
	
	func getPlayerNick(playerId: Int, response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.GetPlayerNick, args: [String(playerId)])
		self.performRequest(request) {
			responseValue in
			
			response(responseValue)
		}
	}
	
	func getCurrentState(playerId: Int, response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.GetGameStatus)
		self.performRequest(request) {
			responseValue in
			
			switch responseValue {
			case .SuccessString(let str):
				if let state = UltimateState.deserialize(str) {
					response(.SuccessState(state))
				} else {
					response(.Error(-1, "Invalid response from server: \(str)"))
				}
			default:
				response(responseValue)
			}
		}
	}
	
	func createGame(playerId: Int, gameType: PlayerType, response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.StartGame, args: [String(gameType.rawValue)])
		self.performRequest(request) {
			responseValue in
			
			switch responseValue {
			case .SuccessString(let str):
				if let gameId = Int(str) {
					response(.SuccessInt(gameId))
				} else {
					response(.Error(-1, "Invalid response from server: \(str)"))
				}
			default:
				response(responseValue)
			}
		}
	}
	
	func getActiveGame(_: Int, response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.GetActiveGame)
		self.performRequest(request) {
			responseValue in
			
			if case .SuccessString(let str) = responseValue {
				let split = str.characters.split(" ")
				
				guard split.count == 2 else {
					return response(.Error(-1, "Invalid response from server: \(str)"))
				}
				
				guard let gameId = Int(String(split[0])), pieceId = Int(String(split[1])) else {
					return response(.Error(-1, "Invalid response from server: \(str)"))
				}
				
				response(.SuccessInt2(gameId, pieceId))
				
			} else {
				response(responseValue)
			}
		}
	}
	
	func playPieceOnBoard(playerId: Int, board: GridIndex, slotIndex: GridIndex, response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.MakeMove, args: ["\(board.x)", "\(board.y)", "\(slotIndex.x)", "\(slotIndex.y)"])
		self.performRequest(request) {
			responseValue in
			
			switch responseValue {
			case .SuccessString(let str):
				if let state = UltimateState.deserialize(str) {
					response(.SuccessState(state))
				} else {
					response(.Error(-1, "Invalid response from server: \(str)"))
				}
			default:
				response(responseValue)
			}
		}
	}
	
	func concedeGame(response: (AsyncResponse) -> ()) {
		let request = self.urlRequest(EndPoint.ConcedeGame)
		self.performRequest(request) {
			responseValue in
			
			switch responseValue {
			case .SuccessString(let str):
				if let state = UltimateState.deserialize(str) {
					response(.SuccessState(state))
				} else {
					response(.Error(-1, "Invalid response from server: \(str)"))
				}
			default:
				response(responseValue)
			}
		}
	}
	
	private func urlRequest(endPoint: EndPoint, args: [String]? = nil) -> NSMutableURLRequest {
		guard let url =  NSURL(string: "\(requestRoot)\(endPoint.replace(variables: args))") else {
			fatalError("Could not make NSURL out of \(requestRoot)\(endPoint.rawValue)")
		}
		let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringCacheData, timeoutInterval: 10.0)
		
		if let playerId = self.savedPlayerId {
			request.addValue("\(playerIdCookieName)=\(playerId)", forHTTPHeaderField: "Cookie")
		}
		return request
	}
	
	// will give either Error or SuccessString responses
	// caller should further interpret SuccessString value
	private func performRequest(request: NSURLRequest, callback: (AsyncResponse) -> ()) {
		let task = session.dataTaskWithRequest(request) {
			(data: NSData?, response: NSURLResponse?, error: NSError?) in
			
			guard nil == error else {
				return callback(.Error(error!.code, error!.localizedDescription))
			}
			
			guard let data = data else {
				return callback(.Error(-1, "No response from server"))
			}
			
			let httpResponse = response as! NSHTTPURLResponse
			let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
			
			guard httpResponse.statusCode == 200 else {
				return callback(.Error(httpResponse.statusCode, "Error from server: \(httpResponse.statusCode) \(dataString)"))
			}
				
			callback(.SuccessString(dataString))
		}
		task.resume()
	}
}

