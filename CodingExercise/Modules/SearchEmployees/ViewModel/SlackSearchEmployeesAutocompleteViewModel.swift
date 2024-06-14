//
//  SlackSearchEmployeesAutocompleteViewModel.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Combine
import Foundation
import Network

// MARK: AutocompleteViewModelDelegate
protocol AutocompleteViewModelDelegate: AnyObject {    
    func onSearchFailed(with reason: String)
    func onSearchCompleted()
}

// MARK: - Interfaces
protocol AutocompleteViewModelInterface {
    /*
     * Fetches Slack employees from that match a given a search term
     */
    func fetchSlackEmployees(_ searchTerm: String?, completionHandler: @escaping ([SlackEmployee]) -> Void)
    
    /*
     * Fetches Slack employees from that match a given a search term using combine
     */
    func fetchSlackEmployees(_ searchTerm: String?)
    
    /*
     * Fetch all Slack employees and store it in the documents directory for offline usage
     */
    func fetchAllSlackEmployees()
    
    /*
    * Returns a slack employee at the given position.
    */
    func slackEmployee(at index: Int) -> SlackEmployee?

    /*
     Delegate that allows to send data updates through callback.
    */
    var delegate: AutocompleteViewModelDelegate? { get set }
    
    /*
     Read only slack employees.
    */
    var slackEmployees: [SlackEmployee] { get }
}

// MARK: searchResultTableViewSections
enum searchResultTableViewSections: Hashable {
    case firstSection
}

// MARK: SlackSearchEmployeesAutocompleteViewModel implements AutocompleteViewModelInterface
class SlackSearchEmployeesAutocompleteViewModel: AutocompleteViewModelInterface {

    // private properties
    private let resultsDataProvider: UserSearchResultDataProviderInterface
    private(set) var slackEmployees: [SlackEmployee] = []
    private var backupEmployees: [SlackEmployee] = []
    private var cancellable = Set<AnyCancellable>()
    private var denyListArray = [String]()
    fileprivate let networkMonitor = NWPathMonitor()
    private var connectionobserver: AnyCancellable?
    private var isConnected: Bool = true
    var viewModelMode: ViewModelModes = .online

    // public properties
    public weak var delegate: AutocompleteViewModelDelegate?
    

    // enum for view model network modes
    enum ViewModelModes {
        case online
        case offline
    }

    init(dataProvider: UserSearchResultDataProviderInterface) {
        self.resultsDataProvider = dataProvider
        self.observeConnection(networkMonitor: NetworkMonitor())
    }
    
    func slackEmployee(at index: Int) -> SlackEmployee? {
        guard index < slackEmployees.count else {
            return nil
        }
        
        return slackEmployees[index]
    }
    
    func fetchSlackEmployees(_ searchTerm: String?, completionHandler: @escaping ([SlackEmployee]) -> Void) {
        guard let term = searchTerm, !term.isEmpty else {
            completionHandler([])
            return
        }

        self.resultsDataProvider.fetchUsers(term) { [weak self] users in
            guard let self = self else { return }
            self.slackEmployees.replaceSubrange(0..<self.slackEmployees.count, with: users)
            completionHandler(users)
        }
    }
    
    func fetchSlackEmployees(_ searchTerm: String?) {
        
        guard let term = searchTerm,
              !term.isEmpty else {
            // reset the slack employees when search is cleared
            slackEmployees = []
            return
        }
        
        // Check if the term is in the deny list, then simply fail and bail out soon without making api call.
        if checkIfInTheDenyList(term) {
            handleSearchEmployeeResponseFailure(error: SlackSearchResponseError.searchTermInDenyList)
            return
        }
        
        // check if the app is searching in the offline mode, if so, search from the backup list of all employees
        if viewModelMode == .offline {
            slackEmployees = backupEmployees.filter {
                ($0.username.lowercased().contains(term.lowercased()))||($0.displayName.lowercased().contains(term.lowercased()))
            }
            delegate?.onSearchCompleted()
            return
        }
        
        // fetch the slack employees for a given search term
        resultsDataProvider.fetchSlackEmployees(term)
            .receive(on: RunLoop.main)
            .sink { status in
                switch status {
                case .finished:
                    Logger.logInfo("searched employees successfully")
                    break
                case .failure(let error):
                    if let error = error as? SlackSearchResponseError {
                        self.handleSearchEmployeeResponseFailure(error: error)
                    }
                    break
                }
            } receiveValue: { response in
                self.handleSearchEmployeeResponseSuccess(with: response, searchTerm: term)
            }
            .store(in: &cancellable)
    }
    
    func fetchAllSlackEmployees() {
        resultsDataProvider.fetchAllSlackEmployees()
            .receive(on: RunLoop.main)
            .sink { status in
                switch status {
                case .finished:
                    Logger.logInfo("searched employees successfully")
                    break
                case .failure(let error):
                    if let error = error as? SlackSearchResponseError {
                        // This is preemptive and hence no errors to the user
                        Logger.logInfo("fetching all employees failed with error - \(error)")
                    }
                    break
                }
            } receiveValue: { response in
                self.handleAllEmployeesResponseSuccess(with: response)
            }
            .store(in: &cancellable)
    }
    
    
    // MARK: Private functions
    
    // Observe the network connection.
    private func observeConnection(networkMonitor: NetworkMonitor){
        connectionobserver = networkMonitor.$isConnected
            .sink{ [weak self] isnetworkConnected in
                guard let self = self else { return }
                
                self.isConnected = isnetworkConnected
                Logger.logInfo("isConnected - \(self.isConnected)")
                
                if !self.isConnected {
                    // If app is not connected, set the offline mode and retrieve the last successfull search result.
                    self.viewModelMode = .offline
                    DispatchQueue.global(qos: .background).async { [weak self] in
                        
                        guard let self = self else {return}
                        
                        if let lastSearchedEmployees = self.retrieveLastSuccessfulSearchResultFromDocuments() { //Retrieving the value from documents
                            
                            Logger.logInfo("slack employees from last successfull search - \(lastSearchedEmployees)")
                            self.slackEmployees = lastSearchedEmployees
                            DispatchQueue.main.async {
                                self.delegate?.onSearchCompleted()
                            }
                        } else {
                            self.slackEmployees = []
                        }
                    }
                } else {
                    // if the app comes back to online, switch the viewmodel modes.
                    self.viewModelMode = .online
                }
        }
    }
    
    private func handleSearchEmployeeResponseFailure(error: SlackSearchResponseError) {
        slackEmployees = []
        delegate?.onSearchFailed(with: error.reason)
    }
    
    private func handleSearchEmployeeResponseSuccess(with response: SlackEmployeesSearchResponse, searchTerm: String?){
        
        slackEmployees.replaceSubrange(0..<slackEmployees.count, with: response.users)
        
        if let searchTerm = searchTerm,
           slackEmployees.count == 0 {
            
            // If there are no search results, then add this term to the deny list
            DispatchQueue.global(qos: .background).async { [weak self] in
                _ = self?.addFailedSearchTermToDenyList(searchTerm)
            }

            delegate?.onSearchFailed(with: SlackSearchResponseError.networking.reason)
        } else {
            
            // if there are search results, write it to the documents directory to support in the offline mode
            DispatchQueue.global(qos: .background).async { [weak self] in
                _ = self?.addLastSuccessfulSearchResultToDocuments(self?.slackEmployees ?? [])
            }
        }
        
        delegate?.onSearchCompleted()
    }
    
    private func handleAllEmployeesResponseSuccess(with response: SlackEmployeesSearchResponse){
        
        backupEmployees.replaceSubrange(0..<backupEmployees.count, with: response.users)
        delegate?.onSearchCompleted()
    }
}

// MARK: read and write into denylist, read and write last successful search results.

extension SlackSearchEmployeesAutocompleteViewModel {
    
    // check if search term is in the deny list
    private func checkIfInTheDenyList(_ searchText: String) -> Bool {
        do {
            
            let writablefileurl = try FileManager.default.makeWritableCopy(named: Constants.readWriteDenyListFilename, ofResourceFile:Constants.readOnlydenyListFilename)
            let string = try String(contentsOf: writablefileurl, encoding: .utf8)
            denyListArray = string.components(separatedBy: CharacterSet.newlines)
        }
        catch (let error) {
            Logger.logInfo("fetching denylist failed - \(error.localizedDescription)")
            return false
        }

        return denyListArray.contains(searchText.lowercased())
    }
    
    // Add failed search term to the deny list in documents directory
    private func addFailedSearchTermToDenyList(_ searchText: String) -> Bool {
        denyListArray.append(searchText.lowercased())
        let joinedDenyListString = denyListArray.joined(separator: "\n")
        
        let fileURL = FileManager.default.fileURL(for: Constants.readWriteDenyListFileWithoutExtension,
                                                  extension: Constants.denyListFileExtension)
        
        guard let data = joinedDenyListString.data(using: .utf8) else {
            Logger.logInfo("Unable to convert string to data")
            return false
        }
        
        do {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch( let error) {
            // handle error
            Logger.logInfo("Error on writing strings to file: \(error)")
            return false
        }
        return true
        
    }
    
    // Adding last successfull search result to Documents directory
    private func addLastSuccessfulSearchResultToDocuments(_ slackEmployees: [SlackEmployee]) -> Bool {
        guard slackEmployees.count > 0 else {
            return false
        }
        
        var employeesString: String?
        do {
          
            let slackEmployeesData = try JSONEncoder().encode(slackEmployees)
            employeesString = String(data: slackEmployeesData, encoding: .utf8)
        } catch {
            print(error)
        }
        
        let fileURL = FileManager.default.fileURL(for: Constants.lastSuccessfullSearchResultFilenameWithoutExtension,
                                                  extension: Constants.denyListFileExtension)
        
        guard let employeesString = employeesString,
              let data = employeesString.data(using: .utf8) else {
            Logger.logInfo("Unable to convert string to data")
            return false
        }
        
        do {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch( let error) {
            // handle error
            Logger.logInfo("Error on writing strings to file: \(error)")
            return false
        }
        return true
        
    }
    
    // fetching last successfull search result from Documents directory
    private func retrieveLastSuccessfulSearchResultFromDocuments() -> [SlackEmployee]? {
        
        guard viewModelMode == .offline else {
            return nil
        }
        
        var slackEmployees = [SlackEmployee]()
        do {
            
            let fileURL = FileManager.default.fileURL(for: Constants.lastSuccessfullSearchResultFilenameWithoutExtension,
                                                      extension: Constants.denyListFileExtension)
            let employeesString = try String(contentsOf: fileURL, encoding: .utf8)
            let employeesData = Data(employeesString.utf8)
            slackEmployees = try JSONDecoder().decode([SlackEmployee].self, from: employeesData)
            
        }
        catch (let error) {
            Logger.logInfo("fetching last searched result failed - \(error.localizedDescription)")
            return nil
        }

        return slackEmployees
        
    }
}
