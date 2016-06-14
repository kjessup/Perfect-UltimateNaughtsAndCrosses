import XCTest
@testable import PerfectUltimateNaughtsAndCrosses

class PerfectUltimateNaughtsAndCrossesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        GameStateServer().wipeAllState()
        GameStateServer().initialize()
    }
    
    override func tearDown() {
        super.tearDown()
        GameStateServer().wipeAllState()
    }
    
    func testCreatePlayer() {
        let playerNick = "player 1"
        let gs = GameStateServer()
        let playerId = gs.createPlayer(playerNick)
        XCTAssert(playerId != invalidId)
    }
    
    func testCreatePlayerFail() {
        let playerNick = "player 1"
        let gs = GameStateServer()
        let playerId = gs.createPlayer(playerNick)
        XCTAssert(playerId != invalidId)
        
        let playerId2 = gs.createPlayer(playerNick)
        XCTAssert(playerId2 == invalidId)
    }
    
    func testCreateGame() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
    }
    
    func testGetActiveGame() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        let (fetchedId, piece) = gs.getActiveGameForPlayer(player1Id)
        XCTAssert(fetchedId == gameId)
        XCTAssert(piece == .Ex)
    }
    
    func testGetBoardIds() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        for x in 0..<ultimateSlotCount {
            for y in 0..<ultimateSlotCount {
                
                let boardId = gs.getBoardId(gameId, index: (x, y))
                
                XCTAssert(boardId != invalidId)
            }
        }
    }
    
    func testGetSlotIds() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        for x in 0..<ultimateSlotCount {
            for y in 0..<ultimateSlotCount {
                
                let boardId = gs.getBoardId(gameId, index: (x, y))
                
                XCTAssert(boardId != invalidId)
                
                for x in 0..<ultimateSlotCount {
                    for y in 0..<ultimateSlotCount {
                        
                        let slotId = gs.getSlotId(boardId, index: (x, y))
                        
                        XCTAssert(slotId != invalidId)
                    }
                }
            }
        }
    }
    
    func testTurnSwitch() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        for _ in 0..<5 {
            let id1 = gs.getCurrentPlayer(gameId)
            XCTAssert(id1.0 == player1Id)
            XCTAssert(id1.1 == .Ex)
            
            gs.endTurn(gameId)
            
            let id2 = gs.getCurrentPlayer(gameId)
            XCTAssert(id2.0 == player2Id)
            XCTAssert(id2.1 == .Oh)
            
            gs.endTurn(gameId)
        }
    }
    
    func testEndGameEx() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        do {
            let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
            
            XCTAssert(gameId != invalidId)
            XCTAssert(fieldId != invalidId)
            
            gs.endGame(gameId, winner: .Ex)
            
            let win = gs.getGameWinner(gameId)
            XCTAssert(win == .ExWin)
        }
        
        do {
            let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
            
            XCTAssert(gameId != invalidId)
            XCTAssert(fieldId != invalidId)
            
            gs.endGame(gameId, winner: .Oh)
            
            let win = gs.getGameWinner(gameId)
            XCTAssert(win == .OhWin)
        }
    }
    
    func testBoardOwner() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        let (gameId, _) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        // test all eight possible avenues
        let sequences:[[[(PieceType, Int, Int)]]] = [
            [
                [
                    // across top
                    //xxx
                    //xoo
                    //oxo
                    (.Ex, 0, 0), (.Oh, 1, 1), (.Ex, 2, 0), (.Oh, 2, 1), (.Ex, 1, 2), (.Oh, 0, 2), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 1, 0)
                ],
                [
                    // across mid
                    //xoo
                    //xxx
                    //oxo
                    (.Ex, 0, 0), (.Oh, 1, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 1, 2), (.Oh, 0, 2), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 1, 1)
                ],
                [
                    // across bottom
                    //oxo
                    //xoo
                    //xxx
                    (.Ex, 0, 2), (.Oh, 1, 1), (.Ex, 1, 0), (.Oh, 2, 1), (.Ex, 1, 2), (.Oh, 0, 0), (.Ex, 0, 1), (.Oh, 2, 0), (.Ex, 2, 2)
                ]
            ],
            [
                [
                    // down left
                    //xoo
                    //xox
                    //xxo
                    (.Ex, 0, 0), (.Oh, 1, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 1, 2), (.Oh, 1, 1), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 0, 2)
                ],
                [
                    // down mid
                    //oxo
                    //oxx
                    //xxo
                    (.Ex, 1, 0), (.Oh, 0, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 1), (.Oh, 2, 2), (.Ex, 1, 2)
                ],
                [
                    // down right
                    //oxx
                    //oox
                    //xox
                    (.Ex, 2, 0), (.Oh, 0, 0), (.Ex, 2, 1), (.Oh, 1, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 2)
                ]
            ],
            [
                [
                    // diag from left
                    //xxo
                    //oxo
                    //xox
                    (.Ex, 0, 0), (.Oh, 2, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 2)
                ],
                [
                    // diag from right
                    //oxx
                    //oxo
                    //xox
                    (.Ex, 2, 2), (.Oh, 0, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 0)
                ],
                [
                    // diag from right (dupe for balance)
                    //oxx
                    //oxo
                    //xox
                    (.Ex, 2, 2), (.Oh, 0, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 0)
                ]
            ]
        ]
        
        for y in 0..<ultimateSlotCount {
            for x in 0..<ultimateSlotCount {
                let boardId = gs.getBoardId(gameId, index: (x, y))
                let sequence = sequences[x][y]
                for (p, x, y) in sequence {
                    let owner = gs.getBoardOwner(boardId)
                    XCTAssert(owner == .None, "Owner was \(owner)")
                    let slotId = gs.getSlotId(boardId, index: (x, y))
                    XCTAssert(slotId != invalidId)
                    let set = gs.setSlotOwner(slotId, type: p)
                    XCTAssert(set == true, "While setting \(x) \(y)")
                    let get = gs.getSlotOwner(slotId)
                    XCTAssert(get == p)
                }
                let owner = gs.getBoardOwner(boardId)
                XCTAssert(owner == .Ex)
            }
        }
    }
    
    func testGetBoard() {
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        let boardId = gs.getBoardId(gameId, index: (0, 0))
        do {
            let slotId = gs.getSlotId(boardId, index: (0, 0))
            gs.setSlotOwner(slotId, type: .Ex)
        }
        do {
            let slotId = gs.getSlotId(boardId, index: (2, 2))
            gs.setSlotOwner(slotId, type: .Ex)
        }
        do {
            let slotId = gs.getSlotId(boardId, index: (2, 0))
            gs.setSlotOwner(slotId, type: .Oh)
        }
        
        let board = gs.getBoard(gameId, index: (0, 0))!
        let boardDesc = board.description
        //		print("\(boardDesc)")
        
        XCTAssert(boardDesc == "X_O\n___\n__X")
        
        do {
            let exTst = board[(0, 0)]
            XCTAssert(exTst == .Ex)
        }
        do {
            let exTst = board[(2, 2)]
            XCTAssert(exTst == .Ex)
        }
        do {
            let exTst = board[(2, 0)]
            XCTAssert(exTst == .Oh)
        }
    }
    
    func testGetField() {
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        let boardId = gs.getBoardId(gameId, index: (1, 1))
        do {
            let slotId = gs.getSlotId(boardId, index: (0, 0))
            gs.setSlotOwner(slotId, type: .Ex)
        }
        do {
            let slotId = gs.getSlotId(boardId, index: (2, 2))
            gs.setSlotOwner(slotId, type: .Ex)
        }
        do {
            let slotId = gs.getSlotId(boardId, index: (2, 0))
            gs.setSlotOwner(slotId, type: .Oh)
        }
        
        let field = gs.getField(gameId)!
        
        //		print("\(field)")
        
        let board = field[(1, 1)]
        let boardDesc = board.description
        //		print("\(boardDesc)")
        
        XCTAssert(boardDesc == "X_O\n___\n__X")
        
        do {
            let exTst = board[(0, 0)]
            XCTAssert(exTst == .Ex)
        }
        do {
            let exTst = board[(2, 2)]
            XCTAssert(exTst == .Ex)
        }
        do {
            let exTst = board[(2, 0)]
            XCTAssert(exTst == .Oh)
        }
    }
    
    func testFieldSerialize() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        let (gameId, _) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        // test all eight possible avenues
        let sequences:[[[(PieceType, Int, Int)]]] = [
            [
                [
                    // across top
                    //xxx
                    //xoo
                    //oxo
                    (.Ex, 0, 0), (.Oh, 1, 1), (.Ex, 2, 0), (.Oh, 2, 1), (.Ex, 1, 2), (.Oh, 0, 2), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 1, 0)
                ],
                [
                    // across mid
                    //xoo
                    //xxx
                    //oxo
                    (.Ex, 0, 0), (.Oh, 1, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 1, 2), (.Oh, 0, 2), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 1, 1)
                ],
                [
                    // across bottom
                    //oxo
                    //xoo
                    //xxx
                    (.Ex, 0, 2), (.Oh, 1, 1), (.Ex, 1, 0), (.Oh, 2, 1), (.Ex, 1, 2), (.Oh, 0, 0), (.Ex, 0, 1), (.Oh, 2, 0), (.Ex, 2, 2)
                ]
            ],
            [
                [
                    // down left
                    //xoo
                    //xox
                    //xxo
                    (.Ex, 0, 0), (.Oh, 1, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 1, 2), (.Oh, 1, 1), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 0, 2)
                ],
                [
                    // down mid
                    //oxo
                    //oxx
                    //xxo
                    (.Ex, 1, 0), (.Oh, 0, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 1), (.Oh, 2, 2), (.Ex, 1, 2)
                ],
                [
                    // down right
                    //oxx
                    //oox
                    //xox
                    (.Ex, 2, 0), (.Oh, 0, 0), (.Ex, 2, 1), (.Oh, 1, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 2)
                ]
            ],
            [
                [
                    // diag from left
                    //xxo
                    //oxo
                    //xox
                    (.Ex, 0, 0), (.Oh, 2, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 2)
                ],
                [
                    // diag from right
                    //oxx
                    //oxo
                    //xox
                    (.Ex, 2, 2), (.Oh, 0, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 0)
                ],
                [
                    // diag from right (dupe for balance)
                    //oxx
                    //oxo
                    //xox
                    (.Ex, 2, 2), (.Oh, 0, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 0)
                ]
            ]
        ]
        
        for y in 0..<ultimateSlotCount {
            for x in 0..<ultimateSlotCount {
                let boardId = gs.getBoardId(gameId, index: (x, y))
                let sequence = sequences[x][y]
                for (p, x, y) in sequence {
                    let owner = gs.getBoardOwner(boardId)
                    XCTAssert(owner == .None, "Owner was \(owner)")
                    let slotId = gs.getSlotId(boardId, index: (x, y))
                    XCTAssert(slotId != invalidId)
                    let set = gs.setSlotOwner(slotId, type: p)
                    XCTAssert(set == true, "While setting \(x) \(y)")
                    let get = gs.getSlotOwner(slotId)
                    XCTAssert(get == p)
                }
                let owner = gs.getBoardOwner(boardId)
                XCTAssert(owner == .Ex)
            }
        }
        
        let field = gs.getField(gameId)
        XCTAssert(field != nil)
        let serialized = field!.serialize()
        //		print("\(serialized)")
        var gen = serialized.characters.generate()
        
        for boardY in 0..<ultimateSlotCount {
            for boardX in 0..<ultimateSlotCount {
                let board = gs.getBoard(gameId, index: (boardX, boardY))
                XCTAssert(board != nil)
                for slotY in 0..<ultimateSlotCount {
                    for slotX in 0..<ultimateSlotCount {
                        
                        let piece = board![(slotX, slotY)]
                        
                        let next = gen.next()
                        XCTAssert(next != nil)
                        
                        let nextValue = Int(String(next!))
                        XCTAssert(nextValue != nil)
                        
                        XCTAssert(piece.rawValue == nextValue!, "\(boardX)/\(boardY) - \(slotX)/\(slotY) \(piece) not equal to \(nextValue!)")
                    }
                }
            }
        }
    }
    
    func testFieldDeserialize() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        let (gameId, _) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        // test all eight possible avenues
        let sequences:[[[(PieceType, Int, Int)]]] = [
            [
                [
                    // across top
                    //xxx
                    //xoo
                    //oxo
                    (.Ex, 0, 0), (.Oh, 1, 1), (.Ex, 2, 0), (.Oh, 2, 1), (.Ex, 1, 2), (.Oh, 0, 2), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 1, 0)
                ],
                [
                    // across mid
                    //xoo
                    //xxx
                    //oxo
                    (.Ex, 0, 0), (.Oh, 1, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 1, 2), (.Oh, 0, 2), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 1, 1)
                ],
                [
                    // across bottom
                    //oxo
                    //xoo
                    //xxx
                    (.Ex, 0, 2), (.Oh, 1, 1), (.Ex, 1, 0), (.Oh, 2, 1), (.Ex, 1, 2), (.Oh, 0, 0), (.Ex, 0, 1), (.Oh, 2, 0), (.Ex, 2, 2)
                ]
            ],
            [
                [
                    // down left
                    //xoo
                    //xox
                    //xxo
                    (.Ex, 0, 0), (.Oh, 1, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 1, 2), (.Oh, 1, 1), (.Ex, 0, 1), (.Oh, 2, 2), (.Ex, 0, 2)
                ],
                [
                    // down mid
                    //oxo
                    //oxx
                    //xxo
                    (.Ex, 1, 0), (.Oh, 0, 0), (.Ex, 2, 1), (.Oh, 2, 0), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 1), (.Oh, 2, 2), (.Ex, 1, 2)
                ],
                [
                    // down right
                    //oxx
                    //oox
                    //xox
                    (.Ex, 2, 0), (.Oh, 0, 0), (.Ex, 2, 1), (.Oh, 1, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 2)
                ]
            ],
            [
                [
                    // diag from left
                    //xxo
                    //oxo
                    //xox
                    (.Ex, 0, 0), (.Oh, 2, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 2)
                ],
                [
                    // diag from right
                    //oxx
                    //oxo
                    //xox
                    (.Ex, 2, 2), (.Oh, 0, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 0)
                ],
                [
                    // diag from right (dupe for balance)
                    //oxx
                    //oxo
                    //xox
                    (.Ex, 2, 2), (.Oh, 0, 0), (.Ex, 1, 1), (.Oh, 2, 1), (.Ex, 0, 2), (.Oh, 0, 1), (.Ex, 1, 0), (.Oh, 1, 2), (.Ex, 2, 0)
                ]
            ]
        ]
        
        for y in 0..<ultimateSlotCount {
            for x in 0..<ultimateSlotCount {
                let boardId = gs.getBoardId(gameId, index: (x, y))
                let sequence = sequences[x][y]
                for (p, x, y) in sequence {
                    let owner = gs.getBoardOwner(boardId)
                    XCTAssert(owner == .None, "Owner was \(owner)")
                    let slotId = gs.getSlotId(boardId, index: (x, y))
                    XCTAssert(slotId != invalidId)
                    let set = gs.setSlotOwner(slotId, type: p)
                    XCTAssert(set == true, "While setting \(x) \(y)")
                    let get = gs.getSlotOwner(slotId)
                    XCTAssert(get == p)
                }
                let owner = gs.getBoardOwner(boardId)
                XCTAssert(owner == .Ex)
            }
        }
        
        let field = gs.getField(gameId)
        XCTAssert(field != nil)
        let serialized = field!.serialize()
        
        let deserialized = Field.deserialize(serialized)
        XCTAssert(deserialized != nil)
        
        let reSerialized = deserialized!.serialize()
        
        XCTAssert(serialized == reSerialized)
        XCTAssert(field == deserialized!, "first: \(serialized)\nsecond: \(deserialized!.serialize())")
    }
    
    func testPlayBotsGame() {
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(player1Nick)
        let player2Id = gs.createPlayer(player2Nick)
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        let (gameId, _) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        var winner = PieceType.None
        repeat {
            
            let state = gs.getCurrentPlayer(gameId)
            let bot = RandomMoveBot(gameId: gameId, piece: state.1)
            bot.makeMove(gs)
            
            winner = gs.getGameWinner(gameId)
            
            let field = gs.getField(gameId)
            
            print("\(field!)")
            
        } while winner == PieceType.None
        
        print("winner: \(winner)")
    }

    static var allTests : [(String, (PerfectUltimateNaughtsAndCrossesTests) -> () throws -> Void)] {
        return [
            ("testCreatePlayer", testCreatePlayer),
            ("testCreatePlayerFail", testCreatePlayerFail),
            ("testCreateGame", testCreateGame),
            ("testGetActiveGame", testGetActiveGame),
            ("testGetBoardIds", testGetBoardIds),
            ("testGetSlotIds", testGetSlotIds),
            ("testTurnSwitch", testTurnSwitch),
            ("testEndGameEx", testEndGameEx),
            ("testBoardOwner", testBoardOwner),
            ("testGetBoard", testGetBoard),
            ("testGetField", testGetField),
            ("testFieldSerialize", testFieldSerialize),
            ("testFieldDeserialize", testFieldDeserialize),
            ("testPlayBotsGame", testPlayBotsGame)
        ]
    }
}
