//
//  GameState-Server.swift
//  Ultimate Noughts & Crosses Server
//
//  Created by Kyle Jessup on 2016-04-21.
//  Copyright © 2016 PerfectlySoft. All rights reserved.
//

import PerfectLib
import SQLite

let simpleBotId = -2

struct GameStateServer: GameState {
	
	let forExampleGameDBPath = "./ultimate.db"
	
	func initialize() {
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			// not sure what all to put in here yet
			try sqlite.execute("CREATE TABLE IF NOT EXISTS players (" +
				"id INTEGER PRIMARY KEY, nick TEXT)")
			try sqlite.execute("CREATE UNIQUE INDEX IF NOT EXISTS playersidx ON players (" +
				"nick)")
			
			// state indicates whose turn it is now
			// x and y, if not invalid, indicate which board must be played on
			try sqlite.execute("CREATE TABLE IF NOT EXISTS games (" +
				"id INTEGER PRIMARY KEY, state INTEGER, player_ex INTEGER, player_oh INTEGER, x INTEGER, y INTEGER)")
			
			try sqlite.execute("CREATE TABLE IF NOT EXISTS fields (" +
				"id INTEGER PRIMARY KEY, id_game INTEGER)")
			
			try sqlite.execute("CREATE TABLE IF NOT EXISTS boards (" +
				"id INTEGER PRIMARY KEY, id_field INTEGER, x INTEGER, y INTEGER, owner INTEGER)")
			
			try sqlite.execute("CREATE TABLE IF NOT EXISTS slots (" +
				"id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y INTEGER, owner INTEGER)")
			
		} catch {
			print("Exeption creating SQLite DB \(error)")
			self.wipeAllState()
		}
	}
	
	func wipeAllState() {
		File(forExampleGameDBPath).delete()
	}
	
	private var db: SQLite {
		return try! SQLite(forExampleGameDBPath)
	}
	
	private func validX(x: Int) -> Bool {
		return x < ultimateSlotCount
	}
	
	private func validY(y: Int) -> Bool {
		return y < ultimateSlotCount
	}
	
	// Returns the player id
	func createPlayer(nick: String) -> Int {
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("INSERT INTO players (nick) VALUES (:1)") {
				(stmt:SQLiteStmt) -> () in
				try stmt.bind(1, nick)
			}
			let playerId = sqlite.lastInsertRowID()
			return playerId
		} catch { }
		return invalidId
	}
	
	func getPlayerNick(playerId: Int) -> String? {
		var playerNick: String?
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.forEachRow("SELECT nick FROM players WHERE id = \(playerId)") {
				(stmt:SQLiteStmt, Int) -> () in
				
				playerNick = stmt.columnText(0)
			}
		} catch { }
		return playerNick
	}
	
	// Returns tuple of Game id and field id
	func createGame(playerX playerX: Int, playerO: Int) -> (Int, Int) {
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("BEGIN")
			try sqlite.execute("INSERT INTO games (state, player_ex, player_oh, x, y) VALUES (\(PieceType.Ex.rawValue), \(playerX), \(playerO), \(invalidId), \(invalidId)) ")
			let gameId = sqlite.lastInsertRowID()
			try sqlite.execute("INSERT INTO fields (id_game) VALUES (\(gameId))")
			let fieldId = sqlite.lastInsertRowID()
			try sqlite.execute("COMMIT")
			return (gameId, fieldId)
		} catch { }
		return (invalidId, invalidId)
	}
	
	// returns the game and the player's piece type
	func getActiveGameForPlayer(playerId: Int) -> (Int, PieceType) {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return getActiveGameForPlayer(sqlite, playerId: playerId)
	}
	
	// returns the game and the player's piece type
	private func getActiveGameForPlayer(sqlite: SQLite, playerId: Int) -> (Int, PieceType) {
		var gameId = invalidId
		var piece = PieceType.None
		do {
			try sqlite.forEachRow("SELECT id, player_ex FROM games WHERE (state != \(PieceType.ExWin.rawValue) AND state != \(PieceType.OhWin.rawValue) AND state != \(PieceType.Draw.rawValue)) AND (player_ex = \(playerId) OR player_oh = \(playerId))") {
				(stmt:SQLiteStmt, Int) -> () in
				
				gameId = stmt.columnInt(0)
				
				let ex = stmt.columnInt(1)
				
				if ex == playerId {
					piece = .Ex
				} else {
					piece = .Oh
				}
			}
		} catch { }
		return (gameId, piece)
	}
	
	func getBoard(gameId: Int, index: GridIndex) -> Board? {
		// board (id INTEGER PRIMARY KEY, id_field INTEGER, x INTEGER, y INTEGER, owner INTEGER)
		// slots (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y INTEGER, owner INTEGER)
		var pieces = [[PieceType]](repeating: [PieceType](repeating:.None, count: ultimateSlotCount), count: ultimateSlotCount)
		var owner = PieceType.None
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			let fieldId = self.getFieldId(sqlite, gameId: gameId)
			guard fieldId != invalidId else {
				return nil
			}
			let boardId = self.getBoardId(sqlite, fieldId: fieldId, index: index, orInsert: false)
			guard fieldId != invalidId else {
				return nil
			}
			try sqlite.forEachRow("SELECT x, y, owner FROM slots WHERE id_board = \(boardId)") {
				(stmt:SQLiteStmt, Int) -> () in
				
				let x = stmt.columnInt(0)
				let y = stmt.columnInt(1)
				let owner = PieceType(rawValue: stmt.columnInt(2))!
				
				pieces[y][x] = owner
			}
			owner = self.getBoardOwner(sqlite, boardId: boardId)
		} catch { }
		return Board(slots: pieces, owner: owner)
	}
	
	private func setActiveBoard(sqlite: SQLite, gameId: Int, index: GridIndex) {
		do {
			try sqlite.execute("UPDATE games SET x = \(index.x), y = \(index.y) WHERE id = \(gameId)")
		} catch {}
	}
	
	private func getBoard(sqlite: SQLite, fieldId: Int, index: GridIndex) -> Board? {
		// board (id INTEGER PRIMARY KEY, id_field INTEGER, x INTEGER, y INTEGER, owner INTEGER)
		// slots (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y INTEGER, owner INTEGER)
		var pieces = [[PieceType]](repeating: [PieceType](repeating:.None, count: ultimateSlotCount), count: ultimateSlotCount)
		var owner = PieceType.None
		do {
			let boardId = self.getBoardId(sqlite, fieldId: fieldId, index: index, orInsert: false)
			guard fieldId != invalidId else {
				return nil
			}
			try sqlite.forEachRow("SELECT x, y, owner FROM slots WHERE id_board = \(boardId)") {
				(stmt:SQLiteStmt, Int) -> () in
				
				let x = stmt.columnInt(0)
				let y = stmt.columnInt(1)
				let owner = PieceType(rawValue: stmt.columnInt(2))!
				
				pieces[y][x] = owner
			}
			owner = self.getBoardOwner(sqlite, boardId: boardId)
		} catch { }
		return Board(slots: pieces, owner: owner)
	}
	
	func getField(gameId: Int) -> Field? {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return self.getField(sqlite, gameId: gameId)
	}
	
	private func getField(sqlite: SQLite, gameId: Int) -> Field? {
		var boards = [[Board]]()
		let fieldId = self.getFieldId(sqlite, gameId: gameId)
		guard fieldId != invalidId else {
			return nil
		}
		for y in 0..<ultimateSlotCount {
			var boardRow = [Board]()
			for x in 0..<ultimateSlotCount {
				if let board = self.getBoard(sqlite, fieldId: fieldId, index: (x, y)) {
					boardRow.append(board)
				}
			}
			boards.append(boardRow)
		}
		return Field(slots: boards)
	}
	
	func getBoardId(gameId: Int, index: GridIndex) -> Int {
		guard validX(index.x) && validY(index.y) else {
			return invalidId
		}
		var boardId = invalidId
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("BEGIN")
			let fieldId = self.getFieldId(sqlite, gameId: gameId)
			try sqlite.forEachRow("SELECT id FROM boards WHERE id_field = \(fieldId) AND x = \(index.x) AND y = \(index.y)") {
				(stmt:SQLiteStmt, Int) -> () in
				boardId = stmt.columnInt(0)
			}
			if boardId == invalidId {
				try sqlite.execute("INSERT INTO boards (id_field, x, y, owner) VALUES (\(fieldId), \(index.x), \(index.y), 0)")
				boardId = sqlite.lastInsertRowID()
			}
			try sqlite.execute("COMMIT")
		} catch { }
		return boardId
	}

	private func getBoardId(sqlite: SQLite, fieldId: Int, index: GridIndex, orInsert: Bool) -> Int {
		var boardId = invalidId
		do {
			try sqlite.forEachRow("SELECT id FROM boards WHERE id_field = \(fieldId) AND x = \(index.x) AND y = \(index.y)") {
				(stmt:SQLiteStmt, Int) -> () in
				boardId = stmt.columnInt(0)
			}
			if orInsert && boardId == invalidId {
				try sqlite.execute("INSERT INTO boards (id_field, x, y, owner) VALUES (\(fieldId), \(index.x), \(index.y), 0)")
				boardId = sqlite.lastInsertRowID()
			}
		} catch { }
		return boardId
	}
	
	private func getFieldId(sqlite: SQLite, gameId: Int) -> Int {
		var fieldId = invalidId
		do {
			try sqlite.forEachRow("SELECT id FROM fields WHERE id_game = \(gameId)") {
				(stmt:SQLiteStmt, Int) -> () in
				fieldId = stmt.columnInt(0)
			}
		} catch { }
		return fieldId
	}
	
	func getSlotId(boardId: Int, index: GridIndex) -> Int {
		guard validX(index.x) && validY(index.y) else {
			return invalidId
		}
		var slotId = invalidId
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("BEGIN")
			slotId = self.getSlotId(sqlite, boardId: boardId, index: index)
			try sqlite.execute("COMMIT")
		} catch { }
		return slotId
	}
	
	func getSlotId(sqlite: SQLite, boardId: Int, index: GridIndex) -> Int {
		guard validX(index.x) && validY(index.y) else {
			return invalidId
		}
		var slotId = invalidId
		do {
			try sqlite.forEachRow("SELECT id FROM slots WHERE id_board = \(boardId) AND x = \(index.x) AND y = \(index.y)") {
				(stmt:SQLiteStmt, Int) -> () in
				slotId = stmt.columnInt(0)
			}
			if slotId == invalidId {
				try sqlite.execute("INSERT INTO slots (id_board, x, y, owner) VALUES (\(boardId), \(index.x), \(index.y), 0)")
				slotId = sqlite.lastInsertRowID()
			}
		} catch { }
		return slotId
	}
	
	// returns the actual winner
	func setGameWinner(gameId: Int, to: PieceType) -> PieceType {
		let winner = to.rawValue == PieceType.Ex.rawValue ? PieceType.ExWin : PieceType.OhWin
		var returnedWinner = PieceType.None
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("BEGIN")
			returnedWinner = self.setGameWinner(sqlite, gameId: gameId, to: to)
			try sqlite.execute("COMMIT")
		} catch { }
		return returnedWinner
	}
	
	private func setGameWinner(sqlite: SQLite, gameId: Int, to: PieceType) -> PieceType {
		var winner = PieceType.None
		switch to {
		case .Ex:
			winner = .ExWin
		case .Oh:
			winner = .OhWin
		case .Draw:
			winner = .Draw
		default:
			()
		}
		var returnedWinner = PieceType.None
		do {
			let (_, currentPlayer, _, _) = self.getCurrentPlayer(sqlite, gameId: gameId)
			if currentPlayer.isWinner { // already has a winner
				returnedWinner = currentPlayer
			} else {
				try sqlite.execute("UPDATE games SET state = \(winner.rawValue) WHERE id = \(gameId)")
				returnedWinner = winner
			}
		} catch { }
		return returnedWinner
	}
	
	func getGameWinner(gameId: Int) -> PieceType {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return self.getGameWinner(sqlite, gameId: gameId)
	}
	
	private func getGameWinner(sqlite: SQLite, gameId: Int) -> PieceType {
		let winCheck = self.getCurrentPlayer(sqlite, gameId: gameId)
		if winCheck.1 == .ExWin || winCheck.1 == .OhWin || winCheck.1 == .Draw {
			return winCheck.1
		}
		
		// no outright winner
		// scan to see if someone has won
		let fieldId = self.getFieldId(sqlite, gameId: gameId)
		// ex
		if self.scanAllBoards(sqlite, fieldId: fieldId, type: .Ex) {
			self.setGameWinner(sqlite, gameId: gameId, to: .Ex)
			return .Ex
		}// oh
		else if self.scanAllBoards(sqlite, fieldId: fieldId, type: .Oh) {
			self.setGameWinner(sqlite, gameId: gameId, to: .Oh)
			return .Oh
		}
		
		// check for draw
		do { // if there are non unowned boards then it's a draw
			var count = 0
			try sqlite.forEachRow("SELECT COUNT(*) FROM boards WHERE id_field = \(fieldId) AND owner = 0") {
				(stmt:SQLiteStmt, Int) -> () in
				count = stmt.columnInt(0)
			}
			if count == 0 {
				self.setGameWinner(sqlite, gameId: gameId, to: .Draw)
				return .Draw
			}
		} catch {}
		return .None
	}
	
	// Returns tuple of player ID, piece type for next move and board on which next move must be made
	func getCurrentPlayer(gameId: Int) -> (Int, PieceType, Int, Int) {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return self.getCurrentPlayer(sqlite, gameId: gameId)
	}
	
	// Returns tuple of player ID, piece type for next move and board on which next move must be made
	private func getCurrentPlayer(sqlite: SQLite, gameId: Int) -> (Int, PieceType, Int, Int) {
		var ret = (invalidId, PieceType.None, invalidId, invalidId)
		do {
			try sqlite.forEachRow("SELECT state, player_ex, player_oh, x, y FROM games WHERE id = \(gameId)") {
				(stmt:SQLiteStmt, i:Int) -> () in
				
				let state = stmt.columnInt(0)
				let exId = stmt.columnInt(1)
				let ohId = stmt.columnInt(2)
				let x = stmt.columnInt(3)
				let y = stmt.columnInt(4)
				
				ret.1 = PieceType(rawValue: state)!
				ret.0 = ret.1 == .Ex ? exId : ohId
				ret.2 = x
				ret.3 = y
			}
		} catch { }
		return ret
	}
	
	// Returns tuple of player ID and piece type for next move
	func endTurn(gameId: Int) -> (Int, PieceType) {
		var ret = (invalidId, PieceType.None)
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("BEGIN")
			self.endTurn(sqlite, gameId: gameId)
			try sqlite.execute("COMMIT")
		} catch { }
		return ret
	}
	
	// Returns tuple of player ID and piece type for next move
	private func endTurn(sqlite: SQLite, gameId: Int) -> (Int, PieceType) {
		var ret = (invalidId, PieceType.None)
		do {
			try sqlite.forEachRow("SELECT state, player_ex, player_oh FROM games WHERE id = \(gameId)") {
				(stmt:SQLiteStmt, i:Int) -> () in
				
				let state = stmt.columnInt(0)
				let exId = stmt.columnInt(1)
				let ohId = stmt.columnInt(2)
				
				let oldPiece = PieceType(rawValue: state)!
				
				ret.1 = oldPiece == .Ex ? .Oh : .Ex
				ret.0 = ret.1 == .Ex ? exId : ohId
			}
			try sqlite.execute("UPDATE games SET state = \(ret.1.rawValue) WHERE id = \(gameId)")
		} catch { }
		return ret
	}
	
	func setActiveBoard(gameId: Int, index: GridIndex) {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		self.setActiveBoard(sqlite, gameId: gameId, index: index)
	}
	
	func endGame(gameId: Int, winner: PieceType) {
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			let winnerValue = winner == .Ex ? PieceType.ExWin : PieceType.OhWin
			try sqlite.execute("UPDATE games SET state = \(winnerValue.rawValue) WHERE id = \(gameId)")
		} catch { }
	}
	
	// Returns the winner of the indicated board.
	func getBoardOwner(boardId: Int) -> PieceType {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return self.getBoardOwner(sqlite, boardId: boardId)
	}
	
	// Returns the winner of the indicated board.
	private func getBoardOwner(sqlite: SQLite, boardId: Int) -> PieceType {
		var ret = PieceType.None
		do {
			// see if it has an outright winner
			try sqlite.forEachRow("SELECT owner FROM boards WHERE id = \(boardId) AND owner != 0") {
				(stmt:SQLiteStmt, i:Int) -> () in
				
				let owner = stmt.columnInt(0)
				ret = PieceType(rawValue: owner)!
			}
			if ret == .None {
				// no outright winner
				// scan to see if someone has won
				
				// ex
				if self.scanAllSlots(sqlite, boardId: boardId, type: .Ex) {
					self.setBoardOwner(sqlite, boardId: boardId, type: .Ex)
					ret = .Ex
				}// oh
				else if self.scanAllSlots(sqlite, boardId: boardId, type: .Oh) {
					self.setBoardOwner(sqlite, boardId: boardId, type: .Oh)
					ret = .Oh
				}
				
				// check for draw
				// if there are non unowned slots then it's a draw
				var slotCount = 0
				
				try sqlite.forEachRow("SELECT COUNT(*) FROM slots WHERE id_board = \(boardId)") {
					(stmt:SQLiteStmt, Int) -> () in
					
					slotCount = stmt.columnInt(0)
				}
				var count = 0
				if slotCount == ultimateSlotCount * ultimateSlotCount {
					try sqlite.forEachRow("SELECT COUNT(*) FROM slots WHERE id_board = \(boardId) AND owner = 0") {
						(stmt:SQLiteStmt, Int) -> () in
						count = stmt.columnInt(0)
					}
				} else {
					count = ultimateSlotCount * ultimateSlotCount
				}
				if count == 0 {
					self.setBoardOwner(sqlite, boardId: boardId, type: .Draw)
					ret = .Draw
				}
			}
		} catch { }
		return ret
	}
	
	// Returns the owner of the indicated slot.
	func getSlotOwner(boardId: Int, index: GridIndex) -> PieceType {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return self.getSlotOwner(sqlite, boardId: boardId, index: index)
	}
	
	// Returns the owner of the indicated slot.
	private func getSlotOwner(sqlite: SQLite, boardId: Int, index: GridIndex) -> PieceType {
		var ret = PieceType.None
		do {
			try sqlite.forEachRow("SELECT owner FROM slots WHERE id_board = \(boardId) AND x = \(index.x) AND y = \(index.y)") {
				(stmt:SQLiteStmt, i:Int) -> () in
				let owner = stmt.columnInt(0)
				ret = PieceType(rawValue: owner)!
			}
		} catch { }
		return ret
	}
	
	// Returns the owner of the indicated slot.
	func getSlotOwner(slotId: Int) -> PieceType {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		return self.getSlotOwner(sqlite, slotId: slotId)
	}
	
	// Returns the owner of the indicated slot.
	private func getSlotOwner(sqlite: SQLite, slotId: Int) -> PieceType {
		var ret = PieceType.None
		do {
			try sqlite.forEachRow("SELECT owner FROM slots WHERE id = \(slotId)") {
				(stmt:SQLiteStmt, i:Int) -> () in
				let owner = stmt.columnInt(0)
				ret = PieceType(rawValue: owner)!
			}
		} catch { }
		return ret
	}
	
	// Does sanity check. Returns false if the slot was already marked.
	// Updates the next active board.
	func setSlotOwner(slotId: Int, type: PieceType) -> Bool {
		do {
			let sqlite = self.db
			defer {
				sqlite.close()
			}
			try sqlite.execute("BEGIN")
			let result = self.setSlotOwner(sqlite, slotId: slotId, type: type)
			try sqlite.execute("COMMIT")
			return result
		} catch { }
		return false
	}
	
	// Does sanity check. Returns false if the slot was already marked.
	// Updates the next active board.
	func setSlotOwner(sqlite: SQLite, slotId: Int, type: PieceType) -> Bool {
		do {
			guard self.getSlotOwner(sqlite, slotId: slotId) == .None else {
				return false
			}
			try sqlite.execute("UPDATE slots SET owner = \(type.rawValue) WHERE id = \(slotId)")
			return true
		} catch { }
		return false
	}
	
	private func scanAllSlots(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		if scanSlotsCrossTop(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsCrossMid(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsCrossBottom(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsDownLeft(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsDownMid(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsDownRight(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsDiagLeft(sqlite, boardId: boardId, type: type) {
			return true
		}
		if scanSlotsDiagRight(sqlite, boardId: boardId, type: type) {
			return true
		}
		return false
	}
	
	private func scanSlotsCrossTop(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 0)" +
			"OR (x = 1 AND y = 0)" +
		"OR (x = 2 AND y = 0))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsCrossMid(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 1)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 2 AND y = 1))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsCrossBottom(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 2)" +
			"OR (x = 1 AND y = 2)" +
		"OR (x = 2 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsDownLeft(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 0)" +
			"OR (x = 0 AND y = 1)" +
		"OR (x = 0 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsDownMid(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 1 AND y = 0)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 1 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsDownRight(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 2 AND y = 0)" +
			"OR (x = 2 AND y = 1)" +
		"OR (x = 2 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsDiagLeft(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 0)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 2 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanSlotsDiagRight(sqlite: SQLite, boardId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM slots WHERE id_board = \(boardId) AND owner = \(type.rawValue) " +
			"AND ((x = 2 AND y = 0)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 0 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}

	private func scanAllBoards(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		if scanBoardsCrossTop(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsCrossMid(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsCrossBottom(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsDownLeft(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsDownMid(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsDownRight(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsDiagLeft(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		if scanBoardsDiagRight(sqlite, fieldId: fieldId, type: type) {
			return true
		}
		return false
	}
	
	private func scanBoardsCrossTop(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// boards (id INTEGER PRIMARY KEY, id_field INTEGER, x INTEGER, y INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 0)" +
			"OR (x = 1 AND y = 0)" +
		"OR (x = 2 AND y = 0))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsCrossMid(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 1)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 2 AND y = 1))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsCrossBottom(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 2)" +
			"OR (x = 1 AND y = 2)" +
		"OR (x = 2 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsDownLeft(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 0)" +
			"OR (x = 0 AND y = 1)" +
		"OR (x = 0 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsDownMid(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 1 AND y = 0)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 1 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsDownRight(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 2 AND y = 0)" +
			"OR (x = 2 AND y = 1)" +
		"OR (x = 2 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsDiagLeft(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 0 AND y = 0)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 2 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func scanBoardsDiagRight(sqlite: SQLite, fieldId: Int, type: PieceType) -> Bool {
		// (id INTEGER PRIMARY KEY, id_board INTEGER, x INTEGER, y, INTEGER, owner INTEGER)
		let stat = "SELECT count(id) FROM boards WHERE id_field = \(fieldId) AND owner = \(type.rawValue) " +
			"AND ((x = 2 AND y = 0)" +
			"OR (x = 1 AND y = 1)" +
		"OR (x = 0 AND y = 2))"
		var yes = false
		try! sqlite.forEachRow(stat) {
			(stmt:SQLiteStmt, _:Int) -> () in
			yes = 3 == stmt.columnInt(0)
		}
		return yes
	}
	
	private func setBoardOwner(sqlite: SQLite, boardId: Int, type: PieceType) {
		try! sqlite.execute("UPDATE boards SET owner = \(type.rawValue) WHERE id = \(boardId)")
	}
	
	private func getCurrentState(sqlite: SQLite, gameId: Int) -> UltimateState {
		// games (id INTEGER PRIMARY KEY, state INTEGER, player_ex INTEGER, player_oh INTEGER, x INTEGER, y INTEGER)
		var currentPiece = PieceType.None
		var x = 0, y = 0
		do {
			try sqlite.forEachRow("SELECT state, x, y FROM games WHERE id = \(gameId)") {
				(stmt:SQLiteStmt, Int) -> () in
				
				currentPiece = PieceType(rawValue: stmt.columnInt(0))!
				x = stmt.columnInt(1)
				y = stmt.columnInt(2)
			}
		} catch {}
		
		if let field = self.getField(sqlite, gameId: gameId) {
			if currentPiece.isWinner {
				return UltimateState.GameOver(currentPiece, field)
			} else {
				return UltimateState.InPlay(currentPiece, (x, y), field)
			}
		}
		return UltimateState.None
	}
	
	func createPlayer(nick: String, response: (AsyncResponse) -> ()) {
		let id = self.createPlayer(nick)
		response(.SuccessInt(id))
	}
	
	func getPlayerNick(playerId: Int, response: (AsyncResponse) -> ()) {
		if let nick = self.getPlayerNick(playerId) {
			response(.SuccessString(nick))
		} else {
			response(.Error(404, "Nick not found"))
		}
	}

	func getCurrentState(playerId: Int, response: (AsyncResponse) -> ()) {
		let sqlite = self.db
		defer {
			sqlite.close()
		}
		do {
			try sqlite.execute("BEGIN")
			let (gameId, _) = self.getActiveGameForPlayer(sqlite, playerId: playerId)
			if gameId != invalidId {
				let state = self.getCurrentState(sqlite, gameId: gameId)
				try sqlite.execute("COMMIT")
				return response(.SuccessState(state))
			}
		} catch {}
		response(.SuccessState(UltimateState.None))
	}
	
	func playPieceOnBoard(playerId: Int, board: GridIndex, slotIndex: GridIndex, response: (AsyncResponse) -> ()) {
		let sqlite = self.db
		
		do {
			try sqlite.execute("BEGIN")
			
			let (gameId, currentPiece) = self.getActiveGameForPlayer(sqlite, playerId: playerId)
			let (turnPlayer, turnPiece, turnBoardX, turnBoardY) = self.getCurrentPlayer(sqlite, gameId: gameId)
			let fieldId = self.getFieldId(sqlite, gameId: gameId)
			let boardId = self.getBoardId(sqlite, fieldId: fieldId, index: board, orInsert: true)
			let boardOwner = self.getBoardOwner(sqlite, boardId: boardId)
			let slotId = self.getSlotId(sqlite, boardId: boardId, index: slotIndex)
			let slotOwner = self.getSlotOwner(sqlite, slotId: slotId)
			
			// check the following:
			// the indicated board is the one that must be played on
			guard turnBoardX == invalidId || (turnBoardX == board.x && turnBoardY == board.y) else {
				return response(.SuccessState(UltimateState.InvalidMove))
			}
			// it is the current player's turn
			guard turnPlayer == playerId && currentPiece == turnPiece else {
				return response(.SuccessState(UltimateState.InvalidMove))
			}
			// the indicated board is unowned
			guard boardOwner == .None else {
				return response(.SuccessState(UltimateState.InvalidMove))
			}
			// the indicated slot is unowned
			guard slotOwner == .None else {
				return response(.SuccessState(UltimateState.InvalidMove))
			}
			
			self.setSlotOwner(sqlite, slotId: slotId, type: turnPiece)
			let _ = self.getBoardOwner(sqlite, boardId: boardId)
			self.endTurn(sqlite, gameId: gameId)
			
			let (nextTurnPlayer, nextTurnPiece, _, _) = self.getCurrentPlayer(sqlite, gameId: gameId)
			
			var winner = self.getGameWinner(sqlite, gameId: gameId)
			if winner == .None {
				
				let boardId = self.getBoardId(sqlite, fieldId: fieldId, index: slotIndex, orInsert: true)
				let boardOwner = self.getBoardOwner(sqlite, boardId: boardId)
				if boardOwner == .None {
					self.setActiveBoard(sqlite, gameId: gameId, index: slotIndex)
				} else {
					self.setActiveBoard(sqlite, gameId: gameId, index: (invalidId, invalidId))
				}
				
				try sqlite.execute("COMMIT")
				
				if nextTurnPlayer == simpleBotId {
					// have the bot make a move
					let bot = RandomMoveBot(gameId: gameId, piece: nextTurnPiece)
					bot.makeMove(self)
					winner = self.getGameWinner(gameId)
				}
			} else {
				try sqlite.execute("COMMIT")
			}
			
			let state = self.getCurrentState(sqlite, gameId: gameId)
			sqlite.close()
			
			print("\(state)")
			
			response(.SuccessState(state))
			
		} catch {
			print("\(error)")
			sqlite.close()
		}
	}
	
	func createGame(playerId: Int, gameType: PlayerType, response: (AsyncResponse) -> ()) {
		response(AsyncResponse.Error(-1, "Should not be called directly"))
	}
	
	func getActiveGame(playerId: Int, response: (AsyncResponse) -> ()) {
		let activeInfo = self.getActiveGameForPlayer(playerId)
		response(AsyncResponse.SuccessString("\(activeInfo.0) \(activeInfo.1.serialize())"))
	}
}










