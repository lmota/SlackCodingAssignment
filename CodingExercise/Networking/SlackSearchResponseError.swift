//
//  SlackSearchResponseError.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation

enum SlackSearchResponseError : Error {

    case networking
    case decoding
    case searchTermInDenyList
    
    var reason: String {
        switch self {
        case .networking:
            return "Failed to search the employees data".localizedCapitalized
        case .decoding:
            return "Internal error ocurred while searching employees".localizedCapitalized
        case .searchTermInDenyList:
            return "Invalid search term. Please try again".localizedCapitalized
            
        }
    }
}

