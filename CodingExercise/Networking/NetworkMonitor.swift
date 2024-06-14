//
//  NetworkMonitor.swift
//
//  Created by Slack Candidate on 2024-06-14.
//

import Foundation
import Network

final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()
    let queue = DispatchQueue(label: "NetworkMonitor")
    let monitor = NWPathMonitor()
    @Published public private(set) var isConnected: Bool = false
    private var hasStatus: Bool = false
    
    init() {
        monitor.pathUpdateHandler = { path in
            #if targetEnvironment(simulator)
                if (!self.hasStatus) {
                    self.isConnected = path.status == .satisfied
                    self.hasStatus = true
                } else {
                    self.isConnected = !self.isConnected
                }
            #else
                self.isConnected = path.status == .satisfied
            #endif
            Logger.logInfo("isConnected: " + String(self.isConnected))
        }
        monitor.start(queue: queue)
    }

}
