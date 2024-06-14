//
//  SlackEmployeeTableViewCell.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import UIKit
/**
 * SlackEmployeeTableViewCell - custom autoCompleteTableViewCell
 */

class SlackEmployeeTableViewCell: UITableViewCell {

    let employeeName: UILabel = {
        let employeeName = UILabel()
        employeeName.translatesAutoresizingMaskIntoConstraints = false
        employeeName.backgroundColor = .clear
        employeeName.textColor = Constants.displayNameColor
        employeeName.textAlignment = .left
        employeeName.numberOfLines = 1
        employeeName.lineBreakMode = .byTruncatingTail
        employeeName.font = UIFont(name: Constants.employeeDisplayNameFont, size: Constants.employeeNameFontSize)
        return employeeName
    }()
    
    let employeeUserId: UILabel = {
        let employeeUserId = UILabel()
        employeeUserId.translatesAutoresizingMaskIntoConstraints = false
        employeeUserId.backgroundColor = .clear
        employeeUserId.textColor = Constants.userNameColor
        employeeUserId.textAlignment = .left
        employeeUserId.numberOfLines = 1
        employeeUserId.lineBreakMode = .byTruncatingTail
        employeeUserId.font = UIFont(name: Constants.employeeUserNameFont, size: Constants.employeeNameFontSize)
        return employeeUserId
    }()
    
    let employeeAvatarImageView: UIImageView = {
        let employeeAvatarImageView = UIImageView()
        employeeAvatarImageView.translatesAutoresizingMaskIntoConstraints = false
        employeeAvatarImageView.createRoundedBorder()
        return employeeAvatarImageView
    }()

    let employeeStackView: UIStackView = {
        let employeeStackView = UIStackView()
        employeeStackView.axis  = .horizontal
        employeeStackView.distribution  = .fillProportionally
        employeeStackView.alignment = .center
        employeeStackView.translatesAutoresizingMaskIntoConstraints = false
        return employeeStackView
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        spinner.color = .lightGray
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: Constants.slackEmployeeCellIdentifier)
        self.backgroundColor = Constants.cellBackgroundColor
        
        setUpUI()
        updateConstraints()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        employeeAvatarImageView.image = UIImage(systemName: Constants.personSystemImageName)
        employeeName.text = ""
        employeeUserId.text = ""
        spinner.stopAnimating()
    }
    
    override func updateConstraints() {
        
        employeeAvatarImageView.widthAnchor.constraint(equalToConstant: Constants.avatarImageViewHeight).isActive = true
        employeeAvatarImageView.heightAnchor.constraint(equalToConstant: Constants.avatarImageViewHeight).isActive = true
        
        employeeAvatarImageView.heightAnchor.constraint(equalToConstant: Constants.avatarImageViewHeight).isActive = true
        employeeUserId.heightAnchor.constraint(equalToConstant: Constants.avatarImageViewHeight).isActive = true
        
        employeeStackView.setCustomSpacing(Constants.customSpacingAfterAvatar, after: employeeAvatarImageView)
        employeeStackView.setCustomSpacing(Constants.customSpacingAfterName, after: employeeAvatarImageView)
        
        employeeStackView.leadingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.leadingAnchor, constant:Constants.employeeStackViewLeadingSpacing).isActive = true
        employeeStackView.trailingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.trailingAnchor, constant: Constants.employeeStackViewLeadingSpacing).isActive = true
        employeeStackView.centerYAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.centerYAnchor).isActive = true
        employeeStackView.heightAnchor.constraint(equalToConstant: Constants.employeeStackViewHeight).isActive = true
        
        super.updateConstraints()
    }
    
    
    func configureCellAt(_ indexPath: IndexPath, viewModel: AutocompleteViewModelInterface) {
        
        guard let slackEmployee = viewModel.slackEmployee(at: indexPath.row) else {
            Logger.logInfo("Unable to fetch the slack employee at the given index")
            return
        }
        
        employeeName.text = slackEmployee.displayName
        employeeUserId.text = slackEmployee.username
        
        // Fetch the avatar image from cache, if not available in cache, fetch from network
        cacheImage(urlString: slackEmployee.avatarURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        employeeStackView.addArrangedSubview(employeeAvatarImageView)
        employeeStackView.addArrangedSubview(employeeName)
        employeeStackView.addArrangedSubview(employeeUserId)
        
        self.contentView.addSubview(employeeStackView)
        self.contentView.addSubview(spinner)
    }

}

let imageCache = NSCache<AnyObject, AnyObject>()

extension SlackEmployeeTableViewCell {
    /**
     *  Fetch the avatar image from cache, if not available in cache, fetch from network
     */
    func cacheImage(urlString: String) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        // setting the default employee profile image
        employeeAvatarImageView.image = UIImage(systemName: Constants.personSystemImageName)
        
        // check if the image is available in the cache, if yes, use the cached image and return
        if let imageFromCache = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            employeeAvatarImageView.image = imageFromCache
            return
        }
        
        spinner.startAnimating()
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            DispatchQueue.main.async { [weak self] in
                   
                   // if no image found then update the UI
                   guard let imageData = data,
                         let imageToCache = UIImage(data: imageData)  else {
                       return
                   }

                   // If image received, set it in the cache and update ui
                   imageCache.setObject(imageToCache, forKey: urlString as AnyObject)
                self?.employeeAvatarImageView.image = imageToCache
                self?.spinner.stopAnimating()
            }
        }.resume()
    }
}
