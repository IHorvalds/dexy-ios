//
//  SavedDefinitionsViewController.swift
//  Dexy
//
//  Created by Tudor Croitoru on 13/04/2022.
//

import UIKit
import CoreData

class SavedDefinitionsViewController: UITableViewController, NSFetchedResultsControllerDelegate, DefinitionCellPopoverDelegate, UIPopoverPresentationControllerDelegate {
    
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
    
    
    private var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    var fetchedResultsController: NSFetchedResultsController<DXDBDefinition>?
    var dataSource: TableDiffableDataSource<String, DXDBDefinition>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "DefinitionTableViewCell", bundle: nil), forCellReuseIdentifier: "definitioncell")
        
        setupDataSource()
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    fileprivate func updateUI() {
        if let context = container?.viewContext {
            context.perform { [weak self] in
                guard let self = self else { return }
                do {
                    try self.fetchedResultsController!.performFetch()
                    
                    var snapshot = NSDiffableDataSourceSnapshot<String, DXDBDefinition>()
                    
                    var titles: [String] = []
                    var definitions: [String: [DXDBDefinition]] = [:]
                    
                    for section in self.fetchedResultsController!.sections! {
                        let objects = section.objects as! [DXDBDefinition]
                        for object in objects {
                            if titles.contains(object.word!) {
                                definitions[object.word!]!.append(object)
                            } else {
                                titles.append(object.word!)
                                definitions[object.word!] = [object]
                            }
                        }
                    }
                    
                    snapshot.appendSections(titles)
                    for section in titles {
                        let _definitions = definitions[section]
                        snapshot.appendItems(_definitions!, toSection: section)
                    }
                    self.dataSource.apply(snapshot, animatingDifferences: true)
                } catch {}
            }
            
        }
    }
    
    fileprivate func setupDataSource() {
        dataSource = TableDiffableDataSource<String, DXDBDefinition>(tableView: tableView, cellProvider: { [weak self] tbv, indx, def in
            guard let self = self else { return UITableViewCell() }
            
            return self.ConfigureCell(tableView: tbv, indexPath: indx, definition: def)
        })
        
        self.dataSource.defaultRowAnimation = .fade
        self.dataSource.titles = TitleForSection
    }
    
    fileprivate func TitleForSection(section: Int) -> String {
        let snapshot = self.dataSource.snapshot()
        return snapshot.sectionIdentifiers[section]
    }
    
    fileprivate func ConfigureCell(tableView: UITableView, indexPath: IndexPath, definition: DXDBDefinition) ->  DefinitionTableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "definitioncell", for: indexPath) as! DefinitionTableViewCell
        
        let def = DefinitionLookup.Definition(id: Int(definition.id),
                                              internalRep: definition.internalRep!,
                                              saved: true,
                                              userNick: definition.userNick!,
                                              sourceName: definition.sourceName!,
                                              createdDate: definition.createdDate!,
                                              modifiedDate: definition.modifiedDate!,
                                              word: definition.word!)
        
        cell.def = def
        cell.delegate = self
        cell.definitionSaverDelegate = self
  
        return cell
    }
    
    fileprivate func setupFetchedResultsController() {
        if let context = container?.viewContext {
            let fetchRequest: NSFetchRequest<DXDBDefinition> = DXDBDefinition.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "word", ascending: false)]
            
            fetchedResultsController = NSFetchedResultsController<DXDBDefinition>(fetchRequest: fetchRequest,
                                                                        managedObjectContext: context,
                                                                        sectionNameKeyPath: nil,
                                                                        cacheName: nil)
            
            fetchedResultsController?.delegate = self
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}

extension SavedDefinitionsViewController: DefinitionSaverDelegate {
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
        
        updateUI()
    }
}
