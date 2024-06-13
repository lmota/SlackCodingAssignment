//
//  SlackSearchEmployeesAutocompleteViewController.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import UIKit


class SlackSearchEmployeesAutocompleteViewController : UIViewController {
    private var viewModel: AutocompleteViewModelInterface

    init(viewModel: AutocompleteViewModelInterface) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = Constants.textFieldPlaceholder
        searchBar.accessibilityLabel = Constants.textFieldPlaceholder
        searchBar.backgroundColor = .clear
        searchBar.isTranslucent = true
        searchBar.barStyle = .black
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()

    private let searchResultsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.cellRowHeight
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Constants.dividerColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 16.0)
        tableView.register(SlackEmployeeTableViewCell.self, forCellReuseIdentifier: Constants.slackEmployeeCellIdentifier)

        return tableView
    }()

    private let contentView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = Constants.searchEmployeesViewControllerTitle
        self.view.backgroundColor = Constants.backgroundColor
        searchBar.delegate = self

        searchResultsTableView.dataSource = self
        searchResultsTableView.delegate = self

        viewModel.delegate = self
        setupSubviews()
    }

    private func setupSubviews() {
        contentView.addSubview(searchBar)
        contentView.addSubview(searchResultsTableView)
        view.addSubview(contentView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.topSpacing),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.leftSpacing),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Constants.rightSpacing),

            searchResultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: Constants.bottomSpacing),
            searchResultsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchResultsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.leftSpacing),
            searchResultsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Constants.rightSpacing)
            ])
    }
}

extension SlackSearchEmployeesAutocompleteViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.fetchSlackEmployees(searchText)
        
        // Reload the tableview and if the search text is cleared, dismiss the keyboard
        searchResultsTableView.reloadData()
        if searchText.isEmpty {
            searchBar.resignFirstResponder()
        }
    }
}

extension SlackSearchEmployeesAutocompleteViewController: AutocompleteViewModelDelegate {

    func onSearchFailed(with reason: String) {
        // display error alert
        let title = Constants.failedToSearchEmployeesTitle.localizedCapitalized
        let action = UIAlertAction(title: Constants.okButtonTitle.localizedUppercase, style: .default)
        self.displayAlert(with: title , message: reason, actions: [action])
    }
    
    func onSearchCompleted() {
        DispatchQueue.main.async {[weak self] in
            self?.searchResultsTableView.reloadData()
        }
    }
}

extension SlackSearchEmployeesAutocompleteViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.slackEmployeeCellIdentifier , for: indexPath) as? SlackEmployeeTableViewCell else {
            return UITableViewCell()
        }
                
        cell.configureCellAt(indexPath, viewModel: viewModel)
        cell.selectionStyle = .none
        
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.slackEmployeesCount()
    }
}

