import XCTest
@testable import Console

class ConsoleMenuControllerTests: ConsoleTestCase {
    func testExitMenu() {
        let mock = makeMockConsole()
        mock.addMockInput(line: "0")
        
        let sut = MenuController(console: mock)
        
        sut.main()
        
        mock.beginOutputAssertion()
            .checkNext("""
            = Menu
            Please select an option bellow:
            """)
            .checkInputEntered("0")
            .checkNext("Babye!")
            .printIfAsserted()
    }
    
    func testInvalidMenuIndex() {
        let mock = makeMockConsole()
        mock.addMockInput(line: "1")
        mock.addMockInput(line: "0")
        
        let sut = MenuController(console: mock)
        
        sut.main()
        
        mock.beginOutputAssertion()
            .checkNext("Please select an option bellow:")
            .checkInputEntered("1")
            .checkNext("""
                = Menu
                Please select an option bellow:
                0: Exit
                Invalid option index 1
                """)
            .checkInputEntered("0")
            .checkNext("Babye!")
            .printIfAsserted()
    }
    
    func testManyChoicedMenu() {
        let mock = makeMockConsole()
        mock.addMockInput(line: "2")
        mock.addMockInput(line: "0")
        
        let sut = TestMenuController(console: mock)
        
        sut.builder = { menu in
            menu.createMenu(name: "Test menu") { (menu, item) in
                for i in 1...10 {
                    menu.addAction(name: "Action \(i)") { menu in
                        menu.console.printLine("Chose \(i)!")
                    }
                }
            }
        }
        
        sut.main()
        
        mock.beginOutputAssertion()
            .checkNext("""
                = Test menu
                Please select an option bellow:
                1: Action 1
                2: Action 2
                3: Action 3
                4: Action 4
                5: Action 5
                6: Action 6
                7: Action 7
                8: Action 8
                9: Action 9
                10: Action 10
                0: Exit
                """)
            .checkInputEntered("2")
            .checkNext("""
                Chose 2!
                = Test menu
                Please select an option bellow:
                1: Action 1
                2: Action 2
                3: Action 3
                4: Action 4
                5: Action 5
                6: Action 6
                7: Action 7
                8: Action 8
                9: Action 9
                10: Action 10
                0: Exit
                """)
            .printIfAsserted()
    }
    
    func testNoMemoryCyclesInMenuBuilding() {
        var didDeinit = false
        let mock = makeMockConsole()
        mock.addMockInput(line: "1")
        mock.addMockInput(line: "0")
        
        autoreleasepool {
            let sut = TestMenuController(console: mock, onDeinit: { didDeinit = true })
            
            sut.main()
            
            mock.beginOutputAssertion()
                .checkNext("Please select an option bellow:")
                .checkInputEntered("1")
                .checkNext("Selected menu 1!")
                .checkNext("Please select an option bellow:")
                .checkInputEntered("0")
                .checkNext("Babye!")
                .printIfAsserted()
        }
        
        XCTAssert(didDeinit)
    }
    
    func testNoMemoryCyclesInMenuWithinMenuBuilding() {
        var didDeinit = false
        let mock = makeMockConsole()
        mock.addMockInput(line: "1")
        mock.addMockInput(line: "1")
        mock.addMockInput(line: "0")
        mock.addMockInput(line: "0")
        
        autoreleasepool {
            let sut = TestMenuController(console: mock, onDeinit: { didDeinit = true })
            sut.builder = { menu in
                menu.createMenu(name: "Menu 1") { menu, item in
                    menu.createMenu(name: "Menu 2") { menu, item in
                        menu.addAction(name: "An action") { menu in
                            menu.console.printLine("Selected Menu 1 - Menu 2")
                            
                            menu.createMenu(name: "Menu 3") { _, _ in }
                        }
                    }
                }
            }
            
            sut.main()
            
            mock.beginOutputAssertion()
                .checkNext("= Menu 1")
                .checkNext("Please select an option bellow:")
                .checkInputEntered("1")
                .checkNext("= Menu 1 = Menu 2")
                .checkNext("Selected Menu 1 - Menu 2")
                .checkInputEntered("0")
                .checkNext("= Menu 1")
                .checkNext("Please select an option bellow:")
                .checkInputEntered("0")
                .checkNext("Babye!")
                .printIfAsserted()
        }
        
        XCTAssert(didDeinit)
    }
}

class TestMenuController: MenuController {
    var onDeinit: () -> ()
    var builder: ((MenuController) -> (MenuController.MenuItem))?
    
    override init(console: ConsoleClient) {
        self.onDeinit = { () in }
        super.init(console: console)
    }
    
    init(console: ConsoleClient, onDeinit: @escaping () -> () = { }) {
        self.onDeinit = onDeinit
        super.init(console: console)
    }
    
    deinit {
        onDeinit()
    }
    
    override func initMenus() -> MenuController.MenuItem {
        if let builder = builder {
            return builder(self)
        }
        
        return createMenu(name: "Main menu") { menu, item in
            menu.addAction(name: "Test menu") { menu in
                menu.console.printLine("Selected menu 1!")
            }
        }
    }
}
