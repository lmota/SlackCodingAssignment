import XCTest
import Combine
@testable import CodingExercise

class SlackSearchEmployeesAutocompleteViewModelTests: XCTestCase {
    
    private var slackSearchResponseFileName = "SlackSearchResponse"
    private lazy var viewModel: SlackSearchEmployeesAutocompleteViewModel = {
        
        let mockSlackApiService = MockSlackAPIServiceProvider(mockResponseFilename: slackSearchResponseFileName)
        let mockSlackApiDataProvider = MockDataProvider(slackAPI: mockSlackApiService)
        return  SlackSearchEmployeesAutocompleteViewModel(dataProvider: mockSlackApiDataProvider)
    }()
    
    override func setUp() {
        super.setUp()

        viewModel.fetchSlackEmployees("S") { slackEmployees in
            Logger.logInfo("Slack employees from mock view model - \(slackEmployees)")
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSlackEmployeesCountForResponseWithNonZeroSearchResults() {
        XCTAssertEqual(viewModel.slackEmployees.count, 8)
    }
    
    func testSlackEmployeeMetaDataForResponseWithNonZeroSearchResults() {
        XCTAssertEqual(viewModel.slackEmployees[0].displayName, "Saniyah Whitehead")
        XCTAssertEqual(viewModel.slackEmployees[0].username, "swhitehead")
        XCTAssertEqual(viewModel.slackEmployees[0].userId, 2)
        XCTAssertEqual(viewModel.slackEmployees[0].avatarURL, "https://randomuser.me/api/portraits/women/89.jpg")
    }
    
    func testSlackEmployeesCountForResponseWithNoResults() {
        
        let mockSlackApiService = MockSlackAPIServiceProvider(mockResponseFilename: "SlackSearchNoResultsResponse")
        let mockSlackApiDataProvider = MockDataProvider(slackAPI: mockSlackApiService)
        viewModel = SlackSearchEmployeesAutocompleteViewModel(dataProvider: mockSlackApiDataProvider)
        
        viewModel.fetchSlackEmployees("X") { slackEmployees in
            Logger.logInfo("Slack employees from mock view model - \(slackEmployees)")
        }
        XCTAssertEqual(viewModel.slackEmployees.count, 0)
    }
    
    func testSlackEmployeesSearchResultUsingCombine() {
        
        viewModel.fetchSlackEmployees("S")
        XCTAssertEqual(viewModel.slackEmployees.count, 8)
        XCTAssertEqual(viewModel.slackEmployees[0].displayName, "Saniyah Whitehead")
        XCTAssertEqual(viewModel.slackEmployees[0].username, "swhitehead")
        XCTAssertEqual(viewModel.slackEmployees[0].userId, 2)
        XCTAssertEqual(viewModel.slackEmployees[0].avatarURL, "https://randomuser.me/api/portraits/women/89.jpg")
        
    }
    
    func testSlackEmployeesErrorResponseUsingCombine() {
        
        let mockSlackApiService = MockSlackAPIServiceProvider(mockResponseFilename: "SlackSearchErrorResponse")
        let mockSlackApiDataProvider = MockDataProvider(slackAPI: mockSlackApiService)
        viewModel = SlackSearchEmployeesAutocompleteViewModel(dataProvider: mockSlackApiDataProvider)
        
        viewModel.fetchSlackEmployees("S")
        XCTAssertEqual(viewModel.slackEmployees.count, 0)
    }
    
    func testSlackEmployeeAtIndex() {
        viewModel.fetchSlackEmployees("S")
        guard let slackEmployee = viewModel.slackEmployee(at: 7) else {
            XCTAssert(true, "failed to fetch employee at the given index")
            return
        }

        XCTAssertEqual(slackEmployee.displayName, "Sasha Brock")
        XCTAssertEqual(slackEmployee.username, "sbrock")
        XCTAssertEqual(slackEmployee.userId, 99)
        XCTAssertEqual(slackEmployee.avatarURL, "https://randomuser.me/api/portraits/women/45.jpg")
    }
    
    func testFetchAllSlackEmployees() {
        let mockSlackApiService = MockSlackAPIServiceProvider(mockResponseFilename: "AllSlackEmployeesResponse")
        let mockSlackApiDataProvider = MockDataProvider(slackAPI: mockSlackApiService)
        viewModel = SlackSearchEmployeesAutocompleteViewModel(dataProvider: mockSlackApiDataProvider)
        
        viewModel.fetchAllSlackEmployees()
        XCTAssertEqual(viewModel.slackEmployees.count, 0)
        
    }
    
    func testViewModelNetworkMode_Offline() {
        XCTAssertEqual(viewModel.viewModelMode, .online)
    }
}

class MockDataProvider : UserSearchResultDataProviderInterface {
    
    var slackAPI: SlackAPIInterface

    init(slackAPI: SlackAPIInterface) {
        self.slackAPI = slackAPI
    }
    
    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([CodingExercise.SlackEmployee]) -> Void) {
        slackAPI.fetchUsers(searchTerm, completionHandler: completionHandler)
    }
    
    func fetchSlackEmployees(_ searchTerm: String) -> AnyPublisher<CodingExercise.SlackEmployeesSearchResponse, Error> {
        slackAPI.fetchSlackEmployees(searchTerm).eraseToAnyPublisher()
    }
    
    func fetchAllSlackEmployees() -> AnyPublisher<CodingExercise.SlackEmployeesSearchResponse, Error> {
        slackAPI.fetchAllSlackEmployees().eraseToAnyPublisher()
    }
}

class MockSlackAPIServiceProvider: SlackAPIInterface {
    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void) {
        do {
            
            let testBundle = Bundle(for: type(of: BundleTestClass()))
            
            guard
                let url = testBundle.url(forResource: mockResponseFilename, withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let slackEmployeesResponse = try? JSONDecoder().decode(SlackEmployeesSearchResponse.self, from: data)
            else {
                completionHandler([])
                return
            }
            
            completionHandler(slackEmployeesResponse.users)
            
        }

    }
    
    func fetchSlackEmployees(_ searchTerm: String) -> AnyPublisher<SlackEmployeesSearchResponse, Error> {

        let testBundle = Bundle(for: type(of: BundleTestClass()))
        
        return testBundle.url(forResource: mockResponseFilename, withExtension: "json")
            .publisher
            .tryMap{ string in
                guard let data = try? Data(contentsOf: string) else {
                    fatalError("Failed to load from bundle.")
                }
                return data
            }
            .decode(type: SlackEmployeesSearchResponse.self, decoder: JSONDecoder())
            .catch { error in
                Fail(error: error)
            }.eraseToAnyPublisher()

    }
    
    func fetchAllSlackEmployees() -> AnyPublisher<CodingExercise.SlackEmployeesSearchResponse, Error> {
        let testBundle = Bundle(for: type(of: BundleTestClass()))
        
        return testBundle.url(forResource: mockResponseFilename, withExtension: "json")
            .publisher
            .tryMap{ string in
                guard let data = try? Data(contentsOf: string) else {
                    fatalError("Failed to load from bundle.")
                }
                return data
            }
            .decode(type: SlackEmployeesSearchResponse.self, decoder: JSONDecoder())
            .catch { error in
                Fail(error: error)
            }.eraseToAnyPublisher()
    }
    
    
    private var mockResponseFilename: String

    init(mockResponseFilename: String) {
        self.mockResponseFilename = mockResponseFilename
    }
    
    class BundleTestClass: XCTestCase { }
}
