import Foundation

// MARK: - Interfaces
protocol UserSearchResultDataProviderInterface {
    /*
     * Fetches users from that match a given a search term
     */
    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void)
}

class UserSearchResultDataProvider: UserSearchResultDataProviderInterface {
    var slackAPI: SlackAPIInterface

    init(slackAPI: SlackAPIInterface) {
        self.slackAPI = slackAPI
    }

    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void) {
        self.slackAPI.fetchUsers(searchTerm) { users in
            completionHandler(users)
        }
    }
}
