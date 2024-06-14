//
//  SlackSearchRequestURL.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation


/**
 * class for SlackSearchRequestURL
 */
class SlackSearchRequestURL {
    /**
     * static function to get the URL for Slack search api
     */
    static func searchSlackEmployeesURL(for searchTerm: String) -> URL? {
        
        guard var urlComponents = URLComponents(string: Constants.slackSearchEndpoint) else {
            return nil
        }

        let queryItemQuery = URLQueryItem(name: Constants.searchTermQueryName, value: searchTerm)
        urlComponents.queryItems = [queryItemQuery]

        guard let url = urlComponents.url else {
            return nil
        }
        return url
    }
    
    /**
     * static function to get the URL for fetching all Slack employees
     */
    static func fetchAllSlackEmployeesURL() -> URL? {
        
        guard let url = URL(string: Constants.slackSearchEndpoint) else {
            return nil
        }

        return url
    }
}
