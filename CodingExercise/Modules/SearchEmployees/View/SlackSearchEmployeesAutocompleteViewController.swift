//
//  SlackSearchEmployeesAutocompleteViewController.swift
//
//  Created by Slack Candidate on 2024-06-13.
//

import UIKit


/**
 * SlackSearchEmployeesAutocompleteViewController, responsible for presenting autocomplete search bar and table view of Slack employees
 */
class SlackSearchEmployeesAutocompleteViewController : UIViewController {

    // private properties
    private var viewModel: AutocompleteViewModelInterface
    private var diffableDataSource: UITableViewDiffableDataSource<searchResultTableViewSections, SlackEmployee>?

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
        tableView.separatorInset = Constants.tableViewSeparatorEdgeInsets
        tableView.register(SlackEmployeeTableViewCell.self, forCellReuseIdentifier: Constants.slackEmployeeCellIdentifier)

        return tableView
    }()

    private let contentView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.hidesWhenStopped = true
        spinner.color = .lightGray
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    
    init(viewModel: AutocompleteViewModelInterface) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // customize the view
        self.title = Constants.searchEmployeesViewControllerTitle
        self.view.backgroundColor = Constants.backgroundColor
        
        // set delegates for search bar, tableview and viewmodel
        searchBar.delegate = self
        searchResultsTableView.delegate = self
        viewModel.delegate = self
        
        // set up subviews
        setupSubviews()
        
        // fetch all the slack employees to support searching in offline mode
        viewModel.fetchAllSlackEmployees()
    }

    private func setupSubviews() {
        // set up tableview
        setUpTableView()
        
        // add subviews
        contentView.addSubview(searchBar)
        contentView.addSubview(searchResultsTableView)
        contentView.addSubview(spinner)
        view.addSubview(contentView)

        // set up constraints
        setupConstraints()
    }
    
    private func setUpTableView() {
        
        // set the diffable datasource for tableview
        diffableDataSource = UITableViewDiffableDataSource(tableView: searchResultsTableView, cellProvider: { [weak self] tableView, indexPath, itemIdentifier in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.slackEmployeeCellIdentifier , for: indexPath) as? SlackEmployeeTableViewCell,
                  let viewModel = self?.viewModel else {
                return UITableViewCell()
            }
                    
            // configure the cell for a given indexPath
            cell.configureCellAt(indexPath, viewModel: viewModel)
            
            // set the cell selection style to none
            cell.selectionStyle = .none
            
            return cell
        })
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            spinner.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.topSpacing),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.leftSpacing),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Constants.rightSpacing),

            searchResultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: Constants.bottomSpacing),
            searchResultsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchResultsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.leftSpacing),
            searchResultsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Constants.rightSpacing)
            ])
    }
    
    // Apply the diffable data source for the tableview
    private func applySnapshot() {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else {
                return
            }
            self.spinner.stopAnimating()
            
            var snapshot = NSDiffableDataSourceSnapshot<searchResultTableViewSections, SlackEmployee>()
            snapshot.appendSections([searchResultTableViewSections.firstSection])
            snapshot.appendItems(self.viewModel.slackEmployees, toSection: searchResultTableViewSections.firstSection)
            self.diffableDataSource?.apply(snapshot)
        }
    }
}

// MARK: UISearchBarDelegate
extension SlackSearchEmployeesAutocompleteViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // fetch the Slack employees for a given term
        spinner.startAnimating()
        viewModel.fetchSlackEmployees(searchText)
        
        // Reload the tableview and if the search text is cleared, dismiss the keyboard
        if searchText.isEmpty {
            searchBar.resignFirstResponder()
            applySnapshot()
        }
    }
}

// MARK: AutocompleteViewModelDelegate
extension SlackSearchEmployeesAutocompleteViewController: AutocompleteViewModelDelegate {

    func onSearchFailed(with reason: String) {

        // display error alert
        let title = Constants.failedToSearchEmployeesTitle.localizedCapitalized
        let action = UIAlertAction(title: Constants.okButtonTitle.localizedUppercase, style: .default)
        self.displayAlert(with: title , message: reason, actions: [action])
        
        // apply the snapshot to update the table with no results
        self.applySnapshot()

    }
    
    func onSearchCompleted() {
        // apply the snapshot to update the table with results
        self.applySnapshot()
    }
}

// MARK: UITableViewDelegate
extension SlackSearchEmployeesAutocompleteViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellRowHeight
    }
}
