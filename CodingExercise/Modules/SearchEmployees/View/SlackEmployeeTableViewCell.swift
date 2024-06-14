//
//  SlackEmployeeTableViewCell.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import UIKit

class SlackEmployeeTableViewCell: UITableViewCell {

    let employeeName: UILabel = {
        let employeeName = UILabel()
        employeeName.translatesAutoresizingMaskIntoConstraints = false
        employeeName.backgroundColor = .clear
        employeeName.textColor = Constants.displayNameColor
        employeeName.textAlignment = .left
        employeeName.numberOfLines = 1
        employeeName.lineBreakMode = .byTruncatingTail
        employeeName.font = UIFont(name: "Lato-Bold", size: 16.0)
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
        employeeUserId.font = UIFont(name: "Lato-Regular", size: 16.0)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
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
    }
    
    private func setUpUI() {
        employeeStackView.addArrangedSubview(employeeAvatarImageView)
        employeeStackView.addArrangedSubview(employeeName)
        employeeStackView.addArrangedSubview(employeeUserId)
        
        self.contentView.addSubview(employeeStackView)
        
    }
    
    override func updateConstraints() {
        
        employeeAvatarImageView.widthAnchor.constraint(equalToConstant: 28.0).isActive = true
        employeeAvatarImageView.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        
        employeeAvatarImageView.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        employeeUserId.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        
        employeeStackView.setCustomSpacing(12.0, after: employeeAvatarImageView)
        employeeStackView.setCustomSpacing(8.0, after: employeeAvatarImageView)
        
        employeeStackView.leadingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.leadingAnchor, constant:16.0).isActive = true
        employeeStackView.trailingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.trailingAnchor, constant: 16.0).isActive = true
        employeeStackView.centerYAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.centerYAnchor).isActive = true
        employeeStackView.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        super.updateConstraints()
    }
    
    
    func configureCellAt(_ indexPath: IndexPath, viewModel: AutocompleteViewModelInterface) {
        
        guard let slackEmployee = viewModel.slackEmployee(at: indexPath.row) else {
            // TODO: log error
            return
        }
        
        employeeName.text = slackEmployee.displayName
        employeeUserId.text = slackEmployee.username
        
        cacheImage(urlString: slackEmployee.avatarURL)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

let imageCache = NSCache<AnyObject, AnyObject>()

extension SlackEmployeeTableViewCell {
    
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
            }
        }.resume()
    }
}