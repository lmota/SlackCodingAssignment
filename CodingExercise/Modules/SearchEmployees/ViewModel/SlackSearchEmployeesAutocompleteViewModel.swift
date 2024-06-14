//
//  SlackSearchEmployeesAutocompleteViewModel.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Combine
import Foundation
import Network

protocol AutocompleteViewModelDelegate: AnyObject {    
    func onSearchFailed(with reason: String)
    func onSearchCompleted()
}

enum searchResultTableViewSections: Hashable {
    case firstSection
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

class SlackSearchEmployeesAutocompleteViewModel: AutocompleteViewModelInterface {

    private let resultsDataProvider: UserSearchResultDataProviderInterface
    private(set) var slackEmployees: [SlackEmployee] = []
    private(set) var backupEmployees: [SlackEmployee] = []
    private var cancellable = Set<AnyCancellable>()
    private var denyListArray = [String]()
    fileprivate let networkMonitor = NWPathMonitor()

    public weak var delegate: AutocompleteViewModelDelegate?
    
    var connectionobserver: AnyCancellable?
    var isConnected: Bool = true
    var viewModelMode: ViewModelModes = .online
    
    enum ViewModelModes {
        case online
        case offline
    }
    
    private func observeConnection(networkMonitor: NetworkMonitor){
        connectionobserver = networkMonitor.$isConnected
            .sink{ [weak self] isnetworkConnected in
                guard let self = self else { return }
                
                self.isConnected = isnetworkConnected
                Logger.logInfo("isConnected - \(self.isConnected)")
                
                if !self.isConnected {
                    
                    self.viewModelMode = .offline
                    DispatchQueue.global(qos: .background).async { [weak self] in
                        
                        guard let self = self else {return}
                        
                        if let lastSearchedEmployees = self.retrieveLastSuccessfulSearchResultFromDocuments() { //Retrieving the value from documents
                            
                            Logger.logInfo("slack employees from last successfull search - \(lastSearchedEmployees)")
                            self.slackEmployees = lastSearchedEmployees
                            DispatchQueue.main.async {
                                self.delegate?.onSearchCompleted()
                            }
                        }
                    }
                } else {
                    self.viewModelMode = .offline
                }
        }
    }

    init(dataProvider: UserSearchResultDataProviderInterface) {
        self.resultsDataProvider = dataProvider
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

        self.resultsDataProvider.fetchUsers(term) { users in
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
        
        if checkIfInTheDenyList(term) {
            handleSearchEmployeeResponseFailure(error: SlackSearchResponseError.searchTermInDenyList)
            return
        }
        
        if viewModelMode == .offline {
            slackEmployees = backupEmployees.filter {
                ($0.username.lowercased().contains(term.lowercased()))||($0.displayName.lowercased().contains(term.lowercased()))
            }
            delegate?.onSearchCompleted()
            return
        }
        
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
    
    
    private func handleSearchEmployeeResponseFailure(error: SlackSearchResponseError) {
        slackEmployees = []
        delegate?.onSearchFailed(with: error.reason)
    }
    
    private func handleSearchEmployeeResponseSuccess(with response: SlackEmployeesSearchResponse, searchTerm: String?){
        
        slackEmployees.replaceSubrange(0..<slackEmployees.count, with: response.users)
        
        if let searchTerm = searchTerm,
           slackEmployees.count == 0 {
            DispatchQueue.global(qos: .background).async { [weak self] in
                _ = self?.addFailedSearchTermToDenyList(searchTerm)
            }

            delegate?.onSearchFailed(with: SlackSearchResponseError.decoding.reason)
        } else {
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

extension SlackSearchEmployeesAutocompleteViewModel {
    
    // check if we need to do this checking on bg queue
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
    
    private func addLastSuccessfulSearchResultToDocuments(_ slackEmployees: [SlackEmployee]) -> Bool {
        guard slackEmployees.count > 0 else {
            return false
        }
        
        var employeesString: String?
        do {
          
            let slackEmployeesData = try JSONEncoder().encode(slackEmployees)
            employeesString = String(data: slackEmployeesData, encoding: .utf8) // true
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
    
    private func retrieveLastSuccessfulSearchResultFromDocuments() -> [SlackEmployee]? {
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
