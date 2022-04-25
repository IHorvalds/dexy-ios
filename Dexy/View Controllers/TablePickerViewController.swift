//
//  TablePickerViewController.swift
//  Dexy
//
//  Created by Tudor Croitoru on 28/02/2021.
//

import UIKit


protocol TablePickerDelegate: AnyObject {
    
    func didSelectItem(item: Any)
    
}

class TablePickerViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    open var options: NSOrderedSet!
    open var labels: [String]!
    
    private var filteredOptions = [Any]()
    private var filteredLabels = [String]()
    
    public var selectedIndex: IndexPath?
    
    public weak var delegate: TablePickerDelegate?
    
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(options.count == labels.count, "Different numbers of options and labels.")
        
        filteredOptions = options.array
        filteredLabels = labels
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "dicționar"
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        definesPresentationContext = false
        
        
        setupRightButton()
    }
    
    fileprivate func setupRightButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(SelectedAnItem))
        self.navigationItem.rightBarButtonItem = doneButton
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredOptions.count
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tableView.estimatedRowHeight = 44.2
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.text = filteredLabels[indexPath.row]
        if indexPath == selectedIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let oldIndexPath = selectedIndex
        selectedIndex = indexPath
        
        if let oldIndexPath = oldIndexPath {
            tableView.reloadRows(at: [oldIndexPath], with: .automatic)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        if searchController.isActive {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func SelectedAnItem() {
        if let selectedIndex = selectedIndex {
            delegate?.didSelectItem(item: filteredOptions[selectedIndex.row] as Any)
            
            self.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

}

extension TablePickerViewController {
    func updateSearchResults(for searchController: UISearchController) {
        if let search = searchController.searchBar.text?.lowercased(),
           !search.isEmpty {
            var _opts = [Any]()
            var _labs = [String]()
            for i in 0..<options.count {
                if labels[i].lowercased().contains(search) {
                    _opts.append(options[i])
                    _labs.append(labels[i])
                }
            }
            
            filteredOptions = _opts
            filteredLabels = _labs
        } else {
            filteredOptions = options.array
            filteredLabels = labels
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
