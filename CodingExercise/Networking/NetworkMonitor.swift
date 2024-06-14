//
//  NetworkMonitor.swift
//
//  Created by Slack Candidate on 2024-06-14.
//

import Foundation
import Network

/*
 * Class to detect device's network status via isConnected published property
 */
final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()
    let queue = DispatchQueue(label: Constants.networkMonitorQueue)
    let monitor = NWPathMonitor()
    @Published public private(set) var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            #if targetEnvironment(simulator)
                self.isConnected = true
            #else
                self.isConnected = path.status == .satisfied
            #endif
            Logger.logInfo("isConnected: " + String(self.isConnected))
        }
        monitor.start(queue: queue)
    }

}
