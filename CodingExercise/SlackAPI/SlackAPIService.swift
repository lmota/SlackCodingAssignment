//
//  SlackApi.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Combine
import Foundation

// MARK: - Interfaces

protocol SlackAPIInterface {
    /*
     * Fetches users from search.team API that match the search term
     */
    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void)
    
    func fetchSlackEmployees(_ searchTerm: String) -> AnyPublisher<SlackEmployeesSearchResponse, Error>
}

class SlackApi: SlackAPIInterface {
    let defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?

    /**
     A global shared SlackApi Instance.
     */
    static public let shared: SlackApi = SlackApi()

    /**
     Fetch Slack users based on a given search term.

     - parameter searchTerm: A string to match users against.
     - parameter completionHandler: The closure invoked when fetching is completed and the user search results are given.
     */
    func fetchUsers(_ searchTerm: String, completionHandler: @escaping ([SlackEmployee]) -> Void) {
        dataTask?.cancel()

        guard var urlComponents = URLComponents(string: Constants.slackSearchEndpoint) else { return }

        let queryItemQuery = URLQueryItem(name: "query", value: searchTerm)
        urlComponents.queryItems = [queryItemQuery]

        guard let url = urlComponents.url else { return }
        dataTask = defaultSession.dataTask(with: url) { data, response, error in
            // These will be the results we return with our completion handler
            var resultsToReturn = [SlackEmployee]()

            // Ensure that our data task is cleaned up and our completion handler is called
            defer {
                self.dataTask = nil
                completionHandler(resultsToReturn)
            }

            if let error = error {
                NSLog("[API] Request failed with error: \(error.localizedDescription)")
                return
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                NSLog("[API] Request returned an invalid response")
                return
            }

            guard response.statusCode == 200 else {
                NSLog("[API] Request returned an unsupported status code: \(response.statusCode)")
                return
            }

            let decoder = JSONDecoder()
            do {
                let result = try decoder.decode(SlackEmployeesSearchResponse.self, from: data)
                resultsToReturn = result.users
            } catch {
                NSLog("[API] Decoding failed with error: \(error)")
            }
        }

        dataTask?.resume()
    }
    
    func fetchSlackEmployees(_ searchTerm: String) -> AnyPublisher<SlackEmployeesSearchResponse, Error> {
        guard let url = SlackSearchRequestURL.searchSlackEmployeesURL(for: searchTerm) else {
            return Fail(error: SlackSearchResponseError.networking).eraseToAnyPublisher()
        }
        
        return defaultSession.dataTaskPublisher(for: url)
            .tryMap { (data: Data, response: URLResponse) in
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    throw SlackSearchResponseError.networking
                }
                return data
            }
            .decode(type: SlackEmployeesSearchResponse.self, decoder: JSONDecoder())
            .tryCatch { _ in
                Fail(error: SlackSearchResponseError.decoding)
            }.eraseToAnyPublisher()
        
        
    }
}
