//
//  SlackEmployeesSearchResponseModel.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation

/**
 *   Slack Employees Search Response model stucture
 */
struct SlackEmployeesSearchResponse: Codable {
    let ok: Bool
    let error: String?
    let users: [SlackEmployee]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ok = try container.decode(Bool.self, forKey: .ok)
        self.error = try container.decodeIfPresent(String.self, forKey: .error)
        self.users = try container.decode([SlackEmployee].self, forKey: .users)
    }
}

/**
 *   Slack employee model stucture
 */
struct SlackEmployee: Codable, Hashable {
    let username: String
    let avatarURL: String
    let displayName: String
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case username
        case avatarURL = "avatar_url"
        case displayName = "display_name"
        case userId = "id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.avatarURL = try container.decode(String.self, forKey: .avatarURL)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.userId = try container.decode(Int.self, forKey: .userId)
    }
}

