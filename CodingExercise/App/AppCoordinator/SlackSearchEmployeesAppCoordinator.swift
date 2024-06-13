//
//  SlackSearchEmployeesAppCoordinator.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation
import UIKit

/**
 *  coordinator protocol
 */
public protocol CoordinatorProtocol {
    var navigationController: UINavigationController {get set}
    
    // Starts the navigation
    func start()
}

/**
 *  Slack search employees app coordinator
 */
class SlackSearchEmployeesAppCoordinator: CoordinatorProtocol {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        SlackSearchEmployeesCoordinator(navigationController: navigationController).start()
    }

}
