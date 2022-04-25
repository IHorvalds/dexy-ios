//
//  DefinitionLookupTableViewController.swift
//  Dexy
//
//  Created by Tudor Croitoru on 13/02/2021.
//

import UIKit
import Alamofire
import CoreData

class DefinitionLookupTableViewController: UITableViewController, DefinitionCellPopoverDelegate, UIPopoverPresentationControllerDelegate {

    private let url = "https://dexonline.ro/definitie##DICT##/##WORD##/json"
    private let searchUrl = "https://dexonline.ro/ajax/searchComplete.php?term=##SEARCH##"
    private let singleDefinitionUrl = "https://dexonline.ro/definitie##DICT##/##WORD##/##ID##"
    
    private var definition: DefinitionLookup?
    private var searchTerm: String?
    private var dictionary: String?
    private var searchResults: [String] = []
    
    private var resultsController: SearchResultsTableViewController!
    private var searchController: UISearchController!
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let noResultsLabel = UILabel()
    

    private let copyrightFooter: UITextView = {
        let textView = UITextView()
        let currentYear = WordOfTheDay.calendar.dateComponents([.year], from: Date()).year!
        
        textView.text = "Definiții preluate de la dexonline\nCopyright © 2004-\(currentYear) dexonline\n( https://dexonline.ro )"
        
        let font = UIFont.systemFont(ofSize: 14.0)
        textView.font = font
        
        textView.textColor = .lightGray
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.dataDetectorTypes = .link
        
        return textView
    }()
    
    var dataSource: TableDiffableDataSource<Int, DefinitionLookup.Definition>! = nil
    
    private var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    private var fetchRequest: NSFetchRequest<DXDBDefinition> = DXDBDefinition.fetchRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "DefinitionTableViewCell", bundle: nil), forCellReuseIdentifier: "definitioncell")
        
        setupNoResultsLabel()
        setupDataSource()
        setupSearchBar()
        setupActivityIndicator()
        update()
        
    }
    
    fileprivate func setupDataSource() {
        dataSource = TableDiffableDataSource<Int, DefinitionLookup.Definition>(tableView: tableView, cellProvider: { [weak self] tbv, indx, def in
            guard let self = self else { return UITableViewCell() }
            
            return self.ConfigureCell(tableView: tbv, index: indx, definition: def)
        })
        
        self.dataSource.defaultRowAnimation = .fade
        self.dataSource.titles = TitleForSection
        
    }
    
    fileprivate func TitleForSection(section: Int) -> String {
        return dictionary ?? ""
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.dataSource.numberOfSections(in: self.tableView) - 1,
           definition != nil,
           (definition?.definitions.count ?? 0) > 0{
            return 100
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == self.dataSource.numberOfSections(in: self.tableView) - 1,
           definition != nil,
           (definition?.definitions.count ?? 0) > 0 {
            
            return self.copyrightFooter
            
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let def = definition?.definitions[indexPath.row] {
            
            let action = UIContextualAction(style: .normal,
                                            title: "Trimite") { [weak self] _, _, handler in
                guard let self = self else { return }
                
                self.shareDefinition(def: def)
                handler(true)
            }
            
            action.backgroundColor = .systemBlue
            action.image = UIImage(systemName: "square.and.arrow.up")
            
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }
    
    fileprivate func ConfigureCell(tableView: UITableView, index: IndexPath, definition: DefinitionLookup.Definition) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "definitioncell", for: index) as! DefinitionTableViewCell
        
        cell.def = definition
        cell.delegate = self
        cell.definitionSaverDelegate = self
  
        return cell
    }
    
    fileprivate func setupSearchBar() {
        resultsController = SearchResultsTableViewController()
        resultsController.delegate = self
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "cuvânt"
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    fileprivate func setupActivityIndicator() {
        let indicatorButton = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = indicatorButton
        activityIndicator.hidesWhenStopped = true
    }
    
    fileprivate func setupNoResultsLabel() {
        self.noResultsLabel.text = "Niciun rezultat"
        self.noResultsLabel.font = .systemFont(ofSize: 32.0)
        self.tableView.addSubview(noResultsLabel)
        
        self.noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        self.noResultsLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.noResultsLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.noResultsLabel.isHidden = true
    }
    
    fileprivate func showNoResultsLabel() {
        noResultsLabel.isHidden = false
    }
    
    fileprivate func hideNoResultsLabel() {
        noResultsLabel.isHidden = true
    }
    
    fileprivate func shareDefinition(def: DefinitionLookup.Definition) {
        let link = singleDefinitionUrl
            .replacingOccurrences(of: "##WORD##",
                                  with: def.word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            .replacingOccurrences(of: "##DICT##",
                                  with: "") // dexonline redirects automatically to the /definitie/WORD/ID, regardless of the dictionary
            .replacingOccurrences(of: "##ID##",
                                  with: String(def.id))
        + "\n\n\(def.formattedDefinition.string)"
        
        let activityController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityController.completionWithItemsHandler = {[unowned self] (nil, completed, _, error) in
            if let error = error {
                let alert = ConnectionAlertBuilder.getAlertViewController(errorKind: .shareError, error: error)
                self.present(alert, animated: true)
                return
            }
            if completed {
                print("completed")
            }else {
                print("cancled")
            }
            
        }
        present(activityController, animated: true, completion: nil)
    }
    
    fileprivate func update() {
        guard let searchTerm = searchTerm,
              !searchTerm.isEmpty else {
            // Clear the screen
            let snapshot = NSDiffableDataSourceSnapshot<Int, DefinitionLookup.Definition>()
            
            self.dataSource.apply(snapshot, animatingDifferences: true)
            
            self.activityIndicator.stopAnimating()
            return
        }
        
        hideNoResultsLabel()
        
        let newUrl = url.replacingOccurrences(of: "##WORD##", with: searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm)
                        .replacingOccurrences(of: "##DICT##", with: (self.dictionary != nil && !self.dictionary!.isEmpty) ? "-\(self.dictionary!)" : "")
        
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        AF.request(newUrl).response { [weak self] response in
            guard let self = self else { return }
            
            switch response.result {
            case .success(let data):
                if let data = data,
                   let definition = DefinitionLookup(data: data) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        self.definition = definition
                        
                        self.updateDefinitionsList()
                        
                        self.activityIndicator.stopAnimating()
                        
                        if definition.definitions.count == 0 {
                            self.showNoResultsLabel()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showNoResultsLabel()
                    }
                }
            case .failure(let error):
                if self.checkConnectivity() {
                    DispatchQueue.main.async {
                        let alert = ConnectionAlertBuilder.getAlertViewController(errorKind: .generalError, error: error)
                        self.present(alert, animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        let alert = ConnectionAlertBuilder.getAlertViewController(errorKind: .connectionError, error: error)
                        self.present(alert, animated: true)
                    }
                }
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    fileprivate func updateDefinitionsList() {
        // Check which of them have been saved
        if var definitions = self.definition?.definitions {
            
            if let context = self.container?.viewContext {
                let ids = definitions.map({$0.id})
                let predicate = NSPredicate(format: "id IN %@", ids)
                self.fetchRequest.predicate = predicate
                
                do {
                    let savedDefinitions = try context.fetch(self.fetchRequest)
                    let savedDefinitionIds = savedDefinitions.map({$0.id})
                    
                    for index in 0..<definitions.count {
                        definitions[index].saved = savedDefinitionIds.contains(Int64(definitions[index].id))
                    }
                    self.definition?.definitions = definitions
                } catch {
                    // If we're here, user may have bigger problems.
                }
           }
            
            var snapshot = NSDiffableDataSourceSnapshot<Int, DefinitionLookup.Definition>()
            snapshot.appendSections([0])
            snapshot.appendItems(definitions)
            
            self.dataSource.apply(snapshot, animatingDifferences: true)

        }
        
    }
    
    
    private func checkConnectivity() -> Bool {
        NetworkReachabilityManager.default?.isReachable ?? false
    }
    
    func openPopover(sourceView: UIView, sourceRect: CGRect, footnote: String) {
        let footnoteVC = UIStoryboard(name: "Popovers", bundle: nil).instantiateViewController(identifier: "footnoteviewcontroller") as! FootnoteViewController
        footnoteVC.footnote = footnote
        footnoteVC.modalPresentationStyle = .popover
        
        if let popoverPresentationController = footnoteVC.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = [.up, .down]
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.delegate = self
            present(footnoteVC, animated: true, completion: nil)
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}

extension DefinitionLookupTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchTerm = searchController.searchBar.text {
            
            self.searchTerm = searchTerm
            self.resultsController.searchTerm = self.searchTerm
            self.resultsController.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            
//            let newUrl = searchUrl.replacingOccurrences(of: "##SEARCH##", with: searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm)
//            AF.request(newUrl).responseJSON { [weak self] response in
//                guard let self = self else { return }
//
//
//                switch response.result {
//                case .success(let json):
//                    if let results = json as? Array<String> {
//                        self.resultsController.searchTerm = self.searchTerm
//                        self.resultsController.searchResults = results
//                        self.resultsController.tableView.reloadData()
//                    }
//                case .failure(let error):
//                    print(error)
//                }
//            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        resignFirstResponder()
        didSelectWord(word: self.resultsController.searchTerm ?? self.searchTerm ?? "")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.navigationItem.title = "Definiții"
        searchController.dismiss(animated: true)
        update()
    }
}

extension DefinitionLookupTableViewController: SearchResultsDelegate {
    
    func didSelectDictionary(dictionary: String) {
        self.dictionary = dictionary
        update()
    }
    
    func didSelectWord(word: String) {
        self.searchTerm = word
        self.searchController.searchBar.text = word
        self.navigationItem.title = "\"\(word)\""
        update()
        searchController.dismiss(animated: true)
    }
}

extension DefinitionLookupTableViewController: DefinitionSaverDelegate {
    func saveDefinition(definition: DefinitionLookup.Definition, cell: DefinitionTableViewCell) {
        
        if definition.saved {
            if let context = self.container?.viewContext {
                let fetchRequest: NSFetchRequest<DXDBDefinition> = DXDBDefinition.fetchRequest()
                let predicate = NSPredicate(format: "id = %d", definition.id)
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = predicate
                
                do {
                    let dxdbDefinitions = try context.fetch(fetchRequest)
                    if !dxdbDefinitions.isEmpty {
                         context.delete(dxdbDefinitions[0])
                         try? context.save()
                     }
                } catch {
                    print(error)
                }
            }
        } else {
            if let context = self.container?.viewContext {
                let dxdbDefinition = DXDBDefinition(context: context)
                dxdbDefinition.id = Int64(definition.id)
                dxdbDefinition.createdDate = definition.createdDate
                dxdbDefinition.internalRep = definition.getInternalRepresentation()
                dxdbDefinition.modifiedDate = definition.modifiedDate
                dxdbDefinition.sourceName = definition.sourceName
                dxdbDefinition.userNick = definition.userNick
                dxdbDefinition.word = definition.word
                
                try? context.save()
            }
        }
        
        updateDefinitionsList()
    }
}
