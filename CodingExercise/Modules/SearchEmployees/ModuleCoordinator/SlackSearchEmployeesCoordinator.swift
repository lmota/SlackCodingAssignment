//
//  SlackSearchEmployeesCoordinator.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation
import UIKit

/**
 * Module coordinator, navigating to the SlackSearchEmployeesAutocompleteViewController
 */
class SlackSearchEmployeesCoordinator: CoordinatorProtocol {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // start auto complete view controller
        let dataProvider = SlackSearchEmployeesResultDataProvider(slackAPI: SlackApi.shared)
        let viewModel = SlackSearchEmployeesAutocompleteViewModel(dataProvider: dataProvider)

        let autocompleteViewController = SlackSearchEmployeesAutocompleteViewController(viewModel: viewModel)
        navigationController.pushViewController(autocompleteViewController, animated: true)
    }
    
    
}
