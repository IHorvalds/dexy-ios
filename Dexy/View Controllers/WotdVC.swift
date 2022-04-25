//
//  ViewController.swift
//  Dexy
//
//  Created by Tudor Croitoru on 10/02/2021.
//

import UIKit
import Kingfisher
import Alamofire

class WotdVC: UITableViewController {
    
    private let url = "https://dexonline.ro/cuvantul-zilei/##DATE##/json"
    private var date: Date = Date()
    private var wordOfTheDay: WordOfTheDay?
    
    private let dateFormatter = DateFormatter()
    
    // MARK: - DiffableDataSource
    private enum Section {
        case selected
        case others
    }
    
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
    
    // swap between them when updating
    @IBOutlet private weak var calendarButton: UIBarButtonItem!
    let indicatorButton = UIBarButtonItem()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var dataSource: TableDiffableDataSource<Section, AnyHashable>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "YYYY/MM/dd"
        
        tableView.register(UINib(nibName: "WotdTableViewCell", bundle: nil), forCellReuseIdentifier: "wotdcell")
        tableView.register(UINib(nibName: "SmallWotdTableViewCell", bundle: nil), forCellReuseIdentifier: "smallwotdcell")
        
        setupDataSource()
        setupActivityIndicator()
        update()
    }
    
    fileprivate func setupActivityIndicator() {
        self.indicatorButton.customView = activityIndicator
        activityIndicator.hidesWhenStopped = true
    }
    
    fileprivate func setupDataSource() {
        dataSource = TableDiffableDataSource<Section, AnyHashable>(tableView: tableView, cellProvider: { [weak self] tbv, indx, wotd in
            guard let self = self else { return UITableViewCell() }
            
            return self.ConfigureCell(tableView: tbv, index: indx, wordOfTheDay: wotd)
        })
        
        self.dataSource.titles = TitleForHeader
        
        self.dataSource.defaultRowAnimation = .fade
    }
    
    fileprivate func TitleForHeader(section: Int) -> String {
        if section == 0 {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return "Cuvântul zilei \(dateFormatter.string(from: self.date))"
        } else {
            return "Cuvinte din alți ani"
        }
    }
    
    fileprivate func ConfigureCell(tableView: UITableView, index: IndexPath, wordOfTheDay wotd: AnyHashable) -> UITableViewCell {
        if index.section == 0,
           let wotd = wotd as? WordOfTheDay {
            let wotdCell: WotdTableViewCell = tableView.dequeueReusableCell(withIdentifier: "wotdcell") as! WotdTableViewCell
            
            wotdCell.wotd = wotd
            
            return wotdCell
        } else {
            let smallWotdCell: SmallWotdTableViewCell = tableView.dequeueReusableCell(withIdentifier: "smallwotdcell") as! SmallWotdTableViewCell
            
            if let wotd = wotd as? WordOfTheDay.SmallWordOfTheDay {
                smallWotdCell.otherWotd = wotd
            } else {
                smallWotdCell.otherWotd = nil
            }
            
            return smallWotdCell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.dataSource.numberOfSections(in: self.tableView) - 1 {
            return 100
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == self.dataSource.numberOfSections(in: self.tableView) - 1 {
            return self.copyrightFooter
        }
        
        return nil
    }
    
    private func update() {
        
        let newUrl = url.replacingOccurrences(of: "##DATE##", with: dateFormatter.string(from: self.date))
        
        self.startUpdating()
        
        AF.request(newUrl).response { [weak self] response in
            guard let self = self else { return }
            
            switch response.result {
                case .success(let data):
                    if let data = data,
                       let wotd = WordOfTheDay(data: data) {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            
                            self.wordOfTheDay = wotd
                            var snapshot = NSDiffableDataSourceSnapshot<Section, AnyHashable>()
                            
                            snapshot.appendSections([.selected, .others])
                            snapshot.appendItems([wotd], toSection: .selected)
                            snapshot.appendItems(wotd.others, toSection: .others)
                            
                            if #available(iOS 15.0, *) {
                                self.dataSource.applySnapshotUsingReloadData(snapshot)
                            } else {
                                self.dataSource.apply(snapshot, animatingDifferences: true)
                            }
//                            snapshot.reloadSections([.selected])
                            
                            self.stopUpdating()
                        }
                    } else {
                        self.stopUpdating()
                    }
                case .failure(let error):
                    if self.checkConnectivity() {
                        let alert = ConnectionAlertBuilder.getAlertViewController(errorKind: .generalError, error: error)
                        self.present(alert, animated: true)
                    } else {
                        let alert = ConnectionAlertBuilder.getAlertViewController(errorKind: .connectionError, error: error)
                        self.present(alert, animated: true)
                    }
                    
                    self.stopUpdating()
            }
        }
    }
    
    fileprivate func startUpdating() {
        self.activityIndicator.isHidden = false
        self.navigationItem.rightBarButtonItem = self.indicatorButton
        self.activityIndicator.startAnimating()
    }
    
    fileprivate func stopUpdating() {
        self.activityIndicator.stopAnimating()
        self.navigationItem.rightBarButtonItem = self.calendarButton
    }
    
    private func checkConnectivity() -> Bool {
        NetworkReachabilityManager.default?.isReachable ?? false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showdaypickersegue",
           let destVC = segue.destination as? DayPickerViewController {
            destVC.currentDate = self.date
            destVC.delegate = self
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1,
           let wotd = wordOfTheDay {
            self.date = wotd.others[indexPath.row].date
            update()
        }
    }
}

extension WotdVC: DayPickerDelegate {
    func didPickDate(date: Date) {
        self.date = date
        self.update()
    }
}

