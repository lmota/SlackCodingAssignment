//
//  SlackSearchEmployeesAutocompleteViewModel.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Combine
import Foundation

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
    private var cancellable = Set<AnyCancellable>()
    private var denyListArray = [String]()

    public weak var delegate: AutocompleteViewModelDelegate?

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
        
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            if self?.checkIfInTheDenyList(term) ?? false {
//                DispatchQueue.main.async {
//                    self?.handleSearchEmployeeResponseFailure(error: SlackSearchResponseError.searchTermInDenyList, searchTerm: term)
//                }
//            }
//        }
        
        if checkIfInTheDenyList(term) {
            handleSearchEmployeeResponseFailure(error: SlackSearchResponseError.searchTermInDenyList, searchTerm: term)
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
                        self.handleSearchEmployeeResponseFailure(error: error, searchTerm: term)
                    }
                    break
                }
            } receiveValue: { response in
                self.handleSearchEmployeeResponseSuccess(with: response, searchTerm: term)
            }
            .store(in: &cancellable)
    }
    
    private func handleSearchEmployeeResponseFailure(error: SlackSearchResponseError, searchTerm: String) {
        slackEmployees = []

        delegate?.onSearchFailed(with: error.reason)
    }
    
    private func handleSearchEmployeeResponseSuccess(with response: SlackEmployeesSearchResponse, searchTerm: String){
        
        slackEmployees.replaceSubrange(0..<slackEmployees.count, with: response.users)
        
        if slackEmployees.count == 0 {
            DispatchQueue.global(qos: .background).async { [weak self] in
                _ = self?.addFailedSearchTermToDenyList(searchTerm)
            }

            delegate?.onSearchFailed(with: SlackSearchResponseError.decoding.reason)
        }
        
        delegate?.onSearchCompleted()
    }
}

extension SlackSearchEmployeesAutocompleteViewModel {
    
    private func checkIfInTheDenyList(_ searchText: String) -> Bool {
        var writablefileurl : URL?
        do{
            
            writablefileurl = try makeWritableCopy(named: "denyListReadWrite1.txt", ofResourceFile: "denylist.txt")
        }
        catch {
            Logger.logInfo("failed to make copy")
        }
        
        guard let writablefileurl = writablefileurl else {
            return false
        }
        
        do {
            print("reading from - \(writablefileurl)")
            let string = try String(contentsOf: writablefileurl, encoding: .utf8)
            denyListArray = string.components(separatedBy: CharacterSet.newlines)
        } catch(let error) {
            Logger.logInfo("fetching denylist failed - \(error.localizedDescription)")
            return false
        }
        return denyListArray.contains(searchText.lowercased())
    }
    
    func makeWritableCopy(named destFileName: String, ofResourceFile originalFileName: String) throws -> URL {
        // Get Documents directory in app bundle
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("No document directory found in application bundle.")
        }

        // Get URL for dest file (in Documents directory)
        let writableFileURL = documentsDirectory.appendingPathComponent(destFileName)

        // If dest file doesn’t exist yet
        if (try? writableFileURL.checkResourceIsReachable()) == nil {
            // Get original (unwritable) file’s URL
            guard let originalFileURL = Bundle.main.url(forResource: originalFileName, withExtension: nil) else {
                fatalError("Cannot find original file “\(originalFileName)” in application bundle’s resources.")
            }

            // Get original file’s contents
            let originalContents = try Data(contentsOf: originalFileURL)

            // Write original file’s contents to dest file
            try originalContents.write(to: writableFileURL, options: .atomic)
            print("Made a writable copy of file “\(originalFileName)” in “\(documentsDirectory)\\\(destFileName)”.")

        } else { // Dest file already exists
            // Print dest file contents
            let contents = try String(contentsOf: writableFileURL, encoding: String.Encoding.utf8)
            print("File “\(destFileName)” already exists in “\(documentsDirectory)”.\nContents:\n\(contents)")
        }

        // Return dest file URL
        return writableFileURL
    }
    
    
    private func addFailedSearchTermToDenyList(_ searchText: String) -> Bool {
        denyListArray.append(searchText.lowercased())
        let joinedDenyListString = denyListArray.joined(separator: "\n")
        
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = URL(fileURLWithPath: "denyListReadWrite1", relativeTo: directoryURL).appendingPathExtension("txt")
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
}
