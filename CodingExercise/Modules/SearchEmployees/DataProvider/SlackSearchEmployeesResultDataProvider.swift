//
//  SlackSearchEmployeesResultDataProvider.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Combine
import Foundation

// MARK: - Interfaces
protocol UserSearchResultDataProviderInterface {
    /*
     * Fetches users from that match a given a search term
     */
    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void)
    
    /*
     * Fetches users from that match a given a search term using combine
     */
    func fetchSlackEmployees(_ searchTerm: String) -> AnyPublisher<SlackEmployeesSearchResponse, Error>
    
    /*
     * Fetches all slack users
     */
    func fetchAllSlackEmployees() -> AnyPublisher<SlackEmployeesSearchResponse, Error>
    
}

// MARK: SlackSearchEmployeesResultDataProvider implments UserSearchResultDataProviderInterface
class SlackSearchEmployeesResultDataProvider: UserSearchResultDataProviderInterface {
    
    var slackAPI: SlackAPIInterface

    init(slackAPI: SlackAPIInterface) {
        self.slackAPI = slackAPI
    }

    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void) {
        self.slackAPI.fetchUsers(searchTerm) { users in
            completionHandler(users)
        }
    }
    
    func fetchSlackEmployees(_ searchTerm: String) -> AnyPublisher<SlackEmployeesSearchResponse, Error> {
        self.slackAPI.fetchSlackEmployees(searchTerm).eraseToAnyPublisher()
    }
    
    func fetchAllSlackEmployees() -> AnyPublisher<SlackEmployeesSearchResponse, Error> {
        self.slackAPI.fetchAllSlackEmployees().eraseToAnyPublisher()
    }
}
