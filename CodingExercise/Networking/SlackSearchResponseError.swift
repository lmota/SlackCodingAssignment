//
//  SlackSearchResponseError.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation

/**
 *  Enumeration for the response failure.
 */
enum SlackSearchResponseError : Error {

    case networking
    case decoding
    case searchTermInDenyList
    
    var reason: String {
        switch self {
        case .networking:
            return "Failed to search the employees data. Please try again".localizedCapitalized
        case .decoding:
            return "Internal error ocurred while searching employees. Please try again".localizedCapitalized
        case .searchTermInDenyList:
            return "Invalid search term. Please try again".localizedCapitalized
            
        }
    }
}

