//
//  SlackSearchEmployeesConstants.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import Foundation
import UIKit

struct Constants {
    static let textFieldPlaceholder = "Search employees by name".localizedCapitalized
    static let searchEmployeesViewControllerTitle = "Search Slack Employees".localizedCapitalized
    static let slackEmployeeCellIdentifier = "SlackEmployeeCustomCell"
    static let slackSearchEndpoint =  "https://mobile-code-exercise-a7fb88c7afa6.herokuapp.com/search"
    static let readWriteDenyListFilename = "denylistReadWrite.txt"
    static let readOnlydenyListFilename = "denylist.txt"
    static let denyListFileExtension = "txt"
    static let readWriteDenyListFileWithoutExtension = "denylistReadWrite"
    static let backgroundColor = UIColor(red:0.925, green: 1.0, blue: 1.0, alpha: 1)
    static let cellBackgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    static let displayNameColor = UIColor(red: 0.113, green: 0.1098, blue: 0.113, alpha: 1)
    static let userNameColor = UIColor(red: 0.3804, green: 0.3765, blue: 0.3804, alpha: 1)
    static let dividerColor = UIColor(red: 0.867, green: 0.867, blue: 0.867, alpha: 1)
    static let personSystemImageName = "person.circle"
    static let failedToSearchEmployeesTitle = "Alert"
    static let okButtonTitle = "Ok"
    static let imageViewCornerRadius = 4.0
    static let cellRowHeight: CGFloat = 44.0
    static let topSpacing: CGFloat = 20.0
    static let leftSpacing: CGFloat = 20.0
    static let bottomSpacing: CGFloat = 20.0
    static let rightSpacing: CGFloat = -20.0
    static let avatarImageViewHeight: CGFloat = 28.0
    static let employeeStackViewHeight: CGFloat = 44.0
    static let employeeStackViewLeadingSpacing: CGFloat = 16.0
    static let customSpacingAfterAvatar: CGFloat = 12.0
    static let customSpacingAfterName: CGFloat = 8.0
    static let employeeNameFontSize: CGFloat = 16.0
    static let employeeDisplayNameFont: String = "Lato-Bold"
    static let employeeUserNameFont: String = "Lato-Regular"
    static let tableViewSeparatorEdgeInsets =  UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 16.0)
    static let searchTermQueryName = "query"
}
