//
//  SlackSearchEmployeesAppCoordinator.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation
import UIKit

/**
 * A generic coordinator protocol.
 * A coordinator is a construct that has the following responsibilities:
 * - Instantiate the next scene's viewController
 * - Inject dependencies into the viewController
 * - Add the viewController to the window either by adding it on the UINavigationController or a UITabBarController
 */
public protocol CoordinatorProtocol {
    var navigationController: UINavigationController {get set}
    
    /**
     * starts the navigation flow:
     * Injects all the dependency in the viewController
     * Adds the viewController on the window (usually through UINavigationController or UITabBarController)
     */
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
        // Invoke start on SlackSearchEmployeesCoordinator i.e. module coordinator
        SlackSearchEmployeesCoordinator(navigationController: navigationController).start()
    }

}
