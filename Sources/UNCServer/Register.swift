//
//  Register.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//
//

import PerfectLib

var waitingPlayerId = invalidId
let waitingPlayerLock = Threading.Lock()

public func PerfectServerModuleInit() {

	GameStateServer().initialize()
	
	// /unc/register/{nick} -> id
	Routing.Routes[EndPoint.RegisterNick.rawValue] = registerNickHandler
	
	// /unc/start/{playertype} -> gameid or invalid id if waiting
	// client can call the /unc/game/ endpoint to check status of wait
	Routing.Routes[EndPoint.StartGame.rawValue] = startGameHandler
	
	// /unc/game/ -> gameid<SP>piecetype
	Routing.Routes[EndPoint.GetActiveGame.rawValue] = getActiveGameHandler
	
	// /unc/concede/ -> UltimateState
	// surrender the current game or stop waiting
	Routing.Routes[EndPoint.ConcedeGame.rawValue] = concedeGameHandler
	
	// /unc/status/ -> UltimateState
	Routing.Routes[EndPoint.GetGameStatus.rawValue] = getGameStatusHandler
	
	// /unc/move/{bx}/{bx}/{x}/{y} -> UltimateState
	Routing.Routes[EndPoint.MakeMove.rawValue] = makeMoveHandler
	
	// /unc/nick/{playerid} -> nick
	Routing.Routes[EndPoint.GetPlayerNick.rawValue] = getPlayerNickHandler
}

func registerNickHandler(request: WebRequest, _ response: WebResponse) {
	
	print("registerNickHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	defer {
		response.requestCompleted()
	}
	
	guard let nick = request.urlVariables["nick"] else {
		return response.badRequest("Player nick not provided")
	}
	
	let gameState = GameStateServer()
	let playerId = gameState.createPlayer(nick)
	
	guard playerId != invalidId else {
		return response.badRequest("Nick could not be registered")
	}
	
	response.appendBodyString("\(playerId)")
}

func getActiveGameHandler(request: WebRequest, _ response: WebResponse) {
	
	print("getActiveGameHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	defer {
		response.requestCompleted()
	}
	
	guard let playerId = request.playerId else {
		return response.badRequest("Could not get active player id")
	}
	
	let gameState = GameStateServer()
	let (gameId, piece) = gameState.getActiveGameForPlayer(playerId)
	
	response.appendBodyString("\(gameId) \(piece.rawValue)")
}

func startGameHandler(request: WebRequest, _ response: WebResponse) {
	
	print("startGameHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	defer {
		response.requestCompleted()
	}
	
	guard let playerId = request.playerId else {
		return response.badRequest("Could not get active player id")
	}
	
	guard let rawType = request.urlVariables["playertype"],
			rawInt = Int(rawType),
			playerType = PlayerType(rawValue: rawInt) else {
		return response.badRequest("Valid player type not provided")
	}
	let gameState = GameStateServer()
	var gameId = invalidId
	if case PlayerType.Bot = playerType {
		// is it a bot
		gameId = gameState.createGame(playerX: playerId, playerO: simpleBotId).0
	} else {
		// we will see if there is a waiting player or wait
		waitingPlayerLock.doWithLock {
			guard waitingPlayerId != playerId else {
				return
			}
			if waitingPlayerId != invalidId {
				gameId = gameState.createGame(playerX: waitingPlayerId, playerO: playerId).0
				waitingPlayerId = invalidId
			} else {
				waitingPlayerId = playerId
			}
		}
	}
	response.appendBodyString("\(gameId)")
}

func concedeGameHandler(request: WebRequest, _ response: WebResponse) {
	
	print("concedeGameHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	defer {
		response.requestCompleted()
	}
	
	guard let playerId = request.playerId else {
		return response.badRequest("Could not get active player id")
	}
	
	let gameState = GameStateServer()
	let (gameId, pieceType) = gameState.getActiveGameForPlayer(playerId)
	
	if gameId == invalidId {
		waitingPlayerLock.doWithLock {
			if waitingPlayerId == playerId {
				waitingPlayerId = invalidId
			}
		}
		let ultimateState = UltimateState.None
		response.appendBodyString(ultimateState.serialize())
	} else {
		let proposedWinner = pieceType.rawValue == PieceType.Ex.rawValue ? PieceType.Oh : PieceType.Ex
		let actualWinner = gameState.setGameWinner(gameId, to: proposedWinner)
		
		guard let field = gameState.getField(gameId) else {
			return response.badRequest("Could not get game field")
		}
		
		let ultimateState = UltimateState.GameOver(actualWinner, field)
		response.appendBodyString(ultimateState.serialize())
	}
}

func getGameStatusHandler(request: WebRequest, _ response: WebResponse) {
	
	print("getGameStatusHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	guard let playerId = request.playerId else {
		response.badRequest("Could not get active player id")
		return response.requestCompleted()
	}
	
	let gameState = GameStateServer()
	gameState.getCurrentState(playerId) {
		ultimateState in
		
		if case .SuccessState(let state) = ultimateState {
			response.appendBodyString(state.serialize())
		} else {
			response.badRequest("Could not get game state")
		}
		response.requestCompleted()
	}
}

func makeMoveHandler(request: WebRequest, _ response: WebResponse) {
	
	print("makeMoveHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	guard let playerId = request.playerId else {
		response.badRequest("Could not get active player id")
		return response.requestCompleted()
	}
	
	guard let bx = request.urlVariables["bx"],
			by = request.urlVariables["by"],
			x = request.urlVariables["x"],
			y = request.urlVariables["y"] else {
		response.badRequest("Moves require board x, y and slot x, y")
		return response.requestCompleted()
	}
	
	guard let bxInt = Int(bx),
			byInt = Int(by),
			xInt = Int(x),
			yInt = Int(y) else {
		response.badRequest("Invalid value for board or slot")
		return response.requestCompleted()
	}
	
	let gameState = GameStateServer()
	gameState.playPieceOnBoard(playerId, board: (bxInt, byInt), slotIndex: (xInt, yInt)) {
		ultimateState in
		
		if case .SuccessState(let state) = ultimateState {
			response.appendBodyString(state.serialize())
		} else {
			response.badRequest("Could not get game state")
		}
		response.requestCompleted()
	}
}

func getPlayerNickHandler(request: WebRequest, _ response: WebResponse) {
	
	print("getPlayerNickHandler")
	
	response.replaceHeader("Content-Type", value: "text/plain")
	
	guard let playerId = request.urlVariables["playerid"], playerIdInt = Int(playerId) else {
		response.badRequest("Player id not provided")
		return response.requestCompleted()
	}
	
	let gameState = GameStateServer()
	gameState.getPlayerNick(playerIdInt) {
		asyncResponse in
		
		if case .SuccessString(let nick) = asyncResponse {
			response.appendBodyString(nick)
		} else {
			response.badRequest("Could not get player nick")
		}
		response.requestCompleted()
	}
	
}












