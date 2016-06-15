//
//  EndPoint.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-26.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

public let playerIdCookieName = "unc-player"

public enum EndPoint: String {
	
	// register a nick, get back a player id
	case RegisterNick = "unc/register/{nick}" // -> id
	
	// client can call the /unc/game/ endpoint to check status of wait
	case StartGame = "unc/start/{playertype}" // -> gameid or invalid id if waiting
	
	// get the active game id and piece type
	case GetActiveGame = "unc/game" // -> active gameid<SP>piecetype
	
	// surrender the current game or stop waiting
	case ConcedeGame = "unc/concede" // -> UltimateState
	
	// get the current game state
	case GetGameStatus = "unc/status" // -> UltimateState
	
	// make a move
	case MakeMove = "unc/move/{bx}/{by}/{x}/{y}" // -> UltimateState
	
	// given a player id, get the nick
	case GetPlayerNick = "unc/nick/{playerid}" // -> nick string
}
