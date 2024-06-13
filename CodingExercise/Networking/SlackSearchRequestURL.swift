//
//  SlackSearchRequestURL.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation


/**
 * structure for SlackSearchRequestURL
 */
struct SlackSearchRequestURL {
    /**
     * static function to get the URL for Slack search api
     */
    static func searchSlackEmployeesURL(for searchTerm: String) -> URL? {
        
        guard var urlComponents = URLComponents(string: Constants.slackSearchEndpoint) else {
            return nil
        }

        let queryItemQuery = URLQueryItem(name: "query", value: searchTerm)
        urlComponents.queryItems = [queryItemQuery]

        guard let url = urlComponents.url else {
            return nil
        }
        
        return url
    }
}
