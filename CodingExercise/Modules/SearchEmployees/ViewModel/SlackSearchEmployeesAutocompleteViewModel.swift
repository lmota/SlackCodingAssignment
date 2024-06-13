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

// MARK: - Interfaces
protocol AutocompleteViewModelInterface {
    /*
     * Fetches Slack employees from that match a given a search term
     */
    func fetchSlackEmployees(_ searchTerm: String?, completionHandler: @escaping ([SlackEmployee]) -> Void)
    func fetchSlackEmployees(_ searchTerm: String?)

    /*
    * Returns a slack employee at the given position.
    */
    func slackEmployee(at index: Int) -> SlackEmployee?

    /*
     * Returns the count of the current slackEmployees array.
     */
    func slackEmployeesCount() -> Int

    /*
     Delegate that allows to send data updates through callback.
    */
    var delegate: AutocompleteViewModelDelegate? { get set }
}

class SlackSearchEmployeesAutocompleteViewModel: AutocompleteViewModelInterface {
    
    private let resultsDataProvider: UserSearchResultDataProviderInterface
    private var slackEmployees: [SlackEmployee] = []
    private var cancellable = Set<AnyCancellable>()

    public weak var delegate: AutocompleteViewModelDelegate?

    init(dataProvider: UserSearchResultDataProviderInterface) {
        self.resultsDataProvider = dataProvider
    }
    
    func slackEmployeesCount() -> Int {
        return slackEmployees.count
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
        
        guard let term = searchTerm, !term.isEmpty else {
            // reset the slack employees when search is cleared
            slackEmployees = []
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
                self.handleSearchEmployeeResponseSuccess(with: response)
            }
            .store(in: &cancellable)
    }
    
    private func handleSearchEmployeeResponseFailure(error: SlackSearchResponseError) {
        delegate?.onSearchFailed(with: error.reason)
    }
    
    private func handleSearchEmployeeResponseSuccess(with response: SlackEmployeesSearchResponse){
        
        slackEmployees.replaceSubrange(0..<slackEmployees.count, with: response.users)
        
        if slackEmployees.count == 0 {
            delegate?.onSearchFailed(with: SlackSearchResponseError.decoding.reason)
        }
        
        delegate?.onSearchCompleted()
    }
}
