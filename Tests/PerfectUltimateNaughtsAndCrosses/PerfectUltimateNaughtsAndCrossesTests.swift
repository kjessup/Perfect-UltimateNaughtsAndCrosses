import XCTest
import UNCShared
@testable import UNCServer

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
        let playerId = gs.createPlayer(nick: playerNick)
        XCTAssert(playerId != invalidId)
    }
    
    func testCreatePlayerFail() {
        let playerNick = "player 1"
        let gs = GameStateServer()
        let playerId = gs.createPlayer(nick: playerNick)
        XCTAssert(playerId != invalidId)
        
        let playerId2 = gs.createPlayer(nick: playerNick)
        XCTAssert(playerId2 == invalidId)
    }
    
    func testCreateGame() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
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
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        let (fetchedId, piece) = gs.getActiveGameForPlayer(playerId: player1Id)
        XCTAssert(fetchedId == gameId)
        XCTAssert(piece == .ex)
    }
    
    func testGetBoardIds() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        for x in 0..<ultimateSlotCount {
            for y in 0..<ultimateSlotCount {
                
                let boardId = gs.getBoardId(gameId: gameId, index: (x, y))
                
                XCTAssert(boardId != invalidId)
            }
        }
    }
    
    func testGetSlotIds() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        for x in 0..<ultimateSlotCount {
            for y in 0..<ultimateSlotCount {
                
                let boardId = gs.getBoardId(gameId: gameId, index: (x, y))
                
                XCTAssert(boardId != invalidId)
                
                for x in 0..<ultimateSlotCount {
                    for y in 0..<ultimateSlotCount {
                        
                        let slotId = gs.getSlotId(boardId: boardId, index: (x, y))
                        
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
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        for _ in 0..<5 {
            let id1 = gs.getActiveGameForPlayer(playerId: gameId)
            XCTAssert(id1.0 == player1Id)
            XCTAssert(id1.1 == .ex)
            
            gs.endTurn(gameId: gameId)
            
            let id2 = gs.getActiveGameForPlayer(playerId: gameId)
            XCTAssert(id2.0 == player2Id)
            XCTAssert(id2.1 == .oh)
            
            gs.endTurn(gameId: gameId)
        }
    }
    
    func testEndGameEx() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        do {
            let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
            
            XCTAssert(gameId != invalidId)
            XCTAssert(fieldId != invalidId)
            
            gs.endGame(gameId: gameId, winner: .ex)
            
            let win = gs.getGameWinner(gameId: gameId)
            XCTAssert(win == .exWin)
        }
        
        do {
            let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
            
            XCTAssert(gameId != invalidId)
            XCTAssert(fieldId != invalidId)
            
            gs.endGame(gameId: gameId, winner: .oh)
            
            let win = gs.getGameWinner(gameId: gameId)
            XCTAssert(win == .ohWin)
        }
    }
    
    func testBoardOwner() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
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
                    (.ex, 0, 0), (.oh, 1, 1), (.ex, 2, 0), (.oh, 2, 1), (.ex, 1, 2), (.oh, 0, 2), (.ex, 0, 1), (.oh, 2, 2), (.ex, 1, 0)
                ],
                [
                    // across mid
                    //xoo
                    //xxx
                    //oxo
                    (.ex, 0, 0), (.oh, 1, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 1, 2), (.oh, 0, 2), (.ex, 0, 1), (.oh, 2, 2), (.ex, 1, 1)
                ],
                [
                    // across bottom
                    //oxo
                    //xoo
                    //xxx
                    (.ex, 0, 2), (.oh, 1, 1), (.ex, 1, 0), (.oh, 2, 1), (.ex, 1, 2), (.oh, 0, 0), (.ex, 0, 1), (.oh, 2, 0), (.ex, 2, 2)
                ]
            ],
            [
                [
                    // down left
                    //xoo
                    //xox
                    //xxo
                    (.ex, 0, 0), (.oh, 1, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 1, 2), (.oh, 1, 1), (.ex, 0, 1), (.oh, 2, 2), (.ex, 0, 2)
                ],
                [
                    // down mid
                    //oxo
                    //oxx
                    //xxo
                    (.ex, 1, 0), (.oh, 0, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 1), (.oh, 2, 2), (.ex, 1, 2)
                ],
                [
                    // down right
                    //oxx
                    //oox
                    //xox
                    (.ex, 2, 0), (.oh, 0, 0), (.ex, 2, 1), (.oh, 1, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 2)
                ]
            ],
            [
                [
                    // diag from left
                    //xxo
                    //oxo
                    //xox
                    (.ex, 0, 0), (.oh, 2, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 2)
                ],
                [
                    // diag from right
                    //oxx
                    //oxo
                    //xox
                    (.ex, 2, 2), (.oh, 0, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 0)
                ],
                [
                    // diag from right (dupe for balance)
                    //oxx
                    //oxo
                    //xox
                    (.ex, 2, 2), (.oh, 0, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 0)
                ]
            ]
        ]
        
        for y in 0..<ultimateSlotCount {
            for x in 0..<ultimateSlotCount {
                let boardId = gs.getBoardId(gameId: gameId, index: (x, y))
                let sequence = sequences[x][y]
                for (p, x, y) in sequence {
                    let owner = gs.getBoardOwner(boardId: boardId)
                    XCTAssert(owner == .none, "Owner was \(owner)")
                    let slotId = gs.getSlotId(boardId: boardId, index: (x, y))
                    XCTAssert(slotId != invalidId)
                    let set = gs.setSlotOwner(slotId: slotId, type: p)
                    XCTAssert(set == true, "While setting \(x) \(y)")
                    let get = gs.getSlotOwner(slotId: slotId)
                    XCTAssert(get == p)
                }
                let owner = gs.getBoardOwner(boardId: boardId)
                XCTAssert(owner == .ex)
            }
        }
    }
    
    func testGetBoard() {
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        let boardId = gs.getBoardId(gameId: gameId, index: (0, 0))
        do {
            let slotId = gs.getSlotId(boardId: boardId, index: (0, 0))
            gs.setSlotOwner(slotId: slotId, type: .ex)
        }
        do {
            let slotId = gs.getSlotId(boardId: boardId, index: (2, 2))
            gs.setSlotOwner(slotId: slotId, type: .ex)
        }
        do {
            let slotId = gs.getSlotId(boardId: boardId, index: (2, 0))
            gs.setSlotOwner(slotId: slotId, type: .oh)
        }
        
        let board = gs.getBoard(gameId: gameId, index: (0, 0))!
        let boardDesc = board.description
        //		print("\(boardDesc)")
        
        XCTAssert(boardDesc == "X_O\n___\n__X")
        
        do {
            let exTst = board[(0, 0)]
            XCTAssert(exTst == .ex)
        }
        do {
            let exTst = board[(2, 2)]
            XCTAssert(exTst == .ex)
        }
        do {
            let exTst = board[(2, 0)]
            XCTAssert(exTst == .oh)
        }
    }
    
    func testGetField() {
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        
        let (gameId, fieldId) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        XCTAssert(gameId != invalidId)
        XCTAssert(fieldId != invalidId)
        
        let boardId = gs.getBoardId(gameId: gameId, index: (1, 1))
        do {
            let slotId = gs.getSlotId(boardId: boardId, index: (0, 0))
            gs.setSlotOwner(slotId: slotId, type: .ex)
        }
        do {
            let slotId = gs.getSlotId(boardId: boardId, index: (2, 2))
            gs.setSlotOwner(slotId: slotId, type: .ex)
        }
        do {
            let slotId = gs.getSlotId(boardId: boardId, index: (2, 0))
            gs.setSlotOwner(slotId: slotId, type: .oh)
        }
        
        let field = gs.getField(gameId: gameId)!
        
        //		print("\(field)")
        
        let board = field[(1, 1)]
        let boardDesc = board.description
        //		print("\(boardDesc)")
        
        XCTAssert(boardDesc == "X_O\n___\n__X")
        
        do {
            let exTst = board[(0, 0)]
            XCTAssert(exTst == .ex)
        }
        do {
            let exTst = board[(2, 2)]
            XCTAssert(exTst == .ex)
        }
        do {
            let exTst = board[(2, 0)]
            XCTAssert(exTst == .oh)
        }
    }
    
    func testFieldSerialize() {
        
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
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
                    (.ex, 0, 0), (.oh, 1, 1), (.ex, 2, 0), (.oh, 2, 1), (.ex, 1, 2), (.oh, 0, 2), (.ex, 0, 1), (.oh, 2, 2), (.ex, 1, 0)
                ],
                [
                    // across mid
                    //xoo
                    //xxx
                    //oxo
                    (.ex, 0, 0), (.oh, 1, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 1, 2), (.oh, 0, 2), (.ex, 0, 1), (.oh, 2, 2), (.ex, 1, 1)
                ],
                [
                    // across bottom
                    //oxo
                    //xoo
                    //xxx
                    (.ex, 0, 2), (.oh, 1, 1), (.ex, 1, 0), (.oh, 2, 1), (.ex, 1, 2), (.oh, 0, 0), (.ex, 0, 1), (.oh, 2, 0), (.ex, 2, 2)
                ]
            ],
            [
                [
                    // down left
                    //xoo
                    //xox
                    //xxo
                    (.ex, 0, 0), (.oh, 1, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 1, 2), (.oh, 1, 1), (.ex, 0, 1), (.oh, 2, 2), (.ex, 0, 2)
                ],
                [
                    // down mid
                    //oxo
                    //oxx
                    //xxo
                    (.ex, 1, 0), (.oh, 0, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 1), (.oh, 2, 2), (.ex, 1, 2)
                ],
                [
                    // down right
                    //oxx
                    //oox
                    //xox
                    (.ex, 2, 0), (.oh, 0, 0), (.ex, 2, 1), (.oh, 1, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 2)
                ]
            ],
            [
                [
                    // diag from left
                    //xxo
                    //oxo
                    //xox
                    (.ex, 0, 0), (.oh, 2, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 2)
                ],
                [
                    // diag from right
                    //oxx
                    //oxo
                    //xox
                    (.ex, 2, 2), (.oh, 0, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 0)
                ],
                [
                    // diag from right (dupe for balance)
                    //oxx
                    //oxo
                    //xox
                    (.ex, 2, 2), (.oh, 0, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 0)
                ]
            ]
        ]
        
        for y in 0..<ultimateSlotCount {
            for x in 0..<ultimateSlotCount {
                let boardId = gs.getBoardId(gameId: gameId, index: (x, y))
                let sequence = sequences[x][y]
                for (p, x, y) in sequence {
                    let owner = gs.getBoardOwner(boardId: boardId)
                    XCTAssert(owner == .none, "Owner was \(owner)")
                    let slotId = gs.getSlotId(boardId: boardId, index: (x, y))
                    XCTAssert(slotId != invalidId)
                    let set = gs.setSlotOwner(slotId: slotId, type: p)
                    XCTAssert(set == true, "While setting \(x) \(y)")
                    let get = gs.getSlotOwner(slotId: slotId)
                    XCTAssert(get == p)
                }
                let owner = gs.getBoardOwner(boardId: boardId)
                XCTAssert(owner == .ex)
            }
        }
        
        let field = gs.getField(gameId: gameId)
        XCTAssert(field != nil)
        let serialized = field!.serialize()
        //		print("\(serialized)")
        var gen = serialized.characters.makeIterator()
        
        for boardY in 0..<ultimateSlotCount {
            for boardX in 0..<ultimateSlotCount {
                let board = gs.getBoard(gameId: gameId, index: (boardX, boardY))
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
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
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
                    (.ex, 0, 0), (.oh, 1, 1), (.ex, 2, 0), (.oh, 2, 1), (.ex, 1, 2), (.oh, 0, 2), (.ex, 0, 1), (.oh, 2, 2), (.ex, 1, 0)
                ],
                [
                    // across mid
                    //xoo
                    //xxx
                    //oxo
                    (.ex, 0, 0), (.oh, 1, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 1, 2), (.oh, 0, 2), (.ex, 0, 1), (.oh, 2, 2), (.ex, 1, 1)
                ],
                [
                    // across bottom
                    //oxo
                    //xoo
                    //xxx
                    (.ex, 0, 2), (.oh, 1, 1), (.ex, 1, 0), (.oh, 2, 1), (.ex, 1, 2), (.oh, 0, 0), (.ex, 0, 1), (.oh, 2, 0), (.ex, 2, 2)
                ]
            ],
            [
                [
                    // down left
                    //xoo
                    //xox
                    //xxo
                    (.ex, 0, 0), (.oh, 1, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 1, 2), (.oh, 1, 1), (.ex, 0, 1), (.oh, 2, 2), (.ex, 0, 2)
                ],
                [
                    // down mid
                    //oxo
                    //oxx
                    //xxo
                    (.ex, 1, 0), (.oh, 0, 0), (.ex, 2, 1), (.oh, 2, 0), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 1), (.oh, 2, 2), (.ex, 1, 2)
                ],
                [
                    // down right
                    //oxx
                    //oox
                    //xox
                    (.ex, 2, 0), (.oh, 0, 0), (.ex, 2, 1), (.oh, 1, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 2)
                ]
            ],
            [
                [
                    // diag from left
                    //xxo
                    //oxo
                    //xox
                    (.ex, 0, 0), (.oh, 2, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 2)
                ],
                [
                    // diag from right
                    //oxx
                    //oxo
                    //xox
                    (.ex, 2, 2), (.oh, 0, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 0)
                ],
                [
                    // diag from right (dupe for balance)
                    //oxx
                    //oxo
                    //xox
                    (.ex, 2, 2), (.oh, 0, 0), (.ex, 1, 1), (.oh, 2, 1), (.ex, 0, 2), (.oh, 0, 1), (.ex, 1, 0), (.oh, 1, 2), (.ex, 2, 0)
                ]
            ]
        ]
        
        for y in 0..<ultimateSlotCount {
            for x in 0..<ultimateSlotCount {
                let boardId = gs.getBoardId(gameId: gameId, index: (x, y))
                let sequence = sequences[x][y]
                for (p, x, y) in sequence {
                    let owner = gs.getBoardOwner(boardId: boardId)
                    XCTAssert(owner == .none, "Owner was \(owner)")
                    let slotId = gs.getSlotId(boardId: boardId, index: (x, y))
                    XCTAssert(slotId != invalidId)
                    let set = gs.setSlotOwner(slotId: slotId, type: p)
                    XCTAssert(set == true, "While setting \(x) \(y)")
                    let get = gs.getSlotOwner(slotId: slotId)
                    XCTAssert(get == p)
                }
                let owner = gs.getBoardOwner(boardId: boardId)
                XCTAssert(owner == .ex)
            }
        }
        
        let field = gs.getField(gameId: gameId)
        XCTAssert(field != nil)
        let serialized = field!.serialize()
        
        let deserialized = Field.deserialize(source: serialized)
        XCTAssert(deserialized != nil)
        
        let reSerialized = deserialized!.serialize()
        
        XCTAssert(serialized == reSerialized)
        XCTAssert(field == deserialized!, "first: \(serialized)\nsecond: \(deserialized!.serialize())")
    }
    
    func testPlayBotsGame() {
        let player1Nick = "player 1"
        let player2Nick = "player 2"
        let gs = GameStateServer()
        let player1Id = gs.createPlayer(nick: player1Nick)
        let player2Id = gs.createPlayer(nick: player2Nick)
        XCTAssert(player1Id != invalidId)
        XCTAssert(player2Id != invalidId)
        let (gameId, _) = gs.createGame(playerX: player1Id, playerO: player2Id)
        
        var winner = PieceType.none
        repeat {
            
            let state = gs.getActiveGameForPlayer(playerId: gameId)
            let bot = RandomMoveBot(gameId: gameId, piece: state.1)
            bot.makeMove(gameState: gs)
            
            winner = gs.getGameWinner(gameId: gameId)
            
            let field = gs.getField(gameId: gameId)
            
            print("\(field!)")
            
        } while winner == PieceType.none
        
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
