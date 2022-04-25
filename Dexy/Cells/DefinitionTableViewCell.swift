//
//  DefinitionTableViewCell.swift
//  Dexy
//
//  Created by Tudor Croitoru on 16/02/2021.
//

import UIKit

protocol DefinitionCellPopoverDelegate: AnyObject {
    func openPopover(sourceView: UIView, sourceRect: CGRect, footnote: String)
}

protocol DefinitionSaverDelegate: AnyObject {
    func saveDefinition(definition: DefinitionLookup.Definition, cell: DefinitionTableViewCell)
}

class DefinitionTableViewCell: UITableViewCell {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var addedByLabel: UILabel!
    @IBOutlet private weak var sourceLabel: UILabel!
    @IBOutlet private weak var saveDefinitionButton: UIButton!
    
    @IBAction private func saveDefinition(_ sender: UIButton) {
        if let definition = self.def {
            self.definitionSaverDelegate?.saveDefinition(definition: definition, cell: self)
        }
    }
    
    public var def: DefinitionLookup.Definition? {
        didSet {
            if let def = self.def {
                
                self.textView.attributedText = def.formattedDefinition
                
                let fieldAttr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0, weight: .regular),
                                 NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
                
                let valueAttr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0, weight: .semibold),
                                 NSAttributedString.Key.foregroundColor: UIColor.label]
                
                // source
                let source = NSMutableAttributedString(string: "Sursa: ", attributes: fieldAttr)
                let sourceName = NSAttributedString(string: def.sourceName, attributes: valueAttr)
                source.append(sourceName)
                self.sourceLabel.attributedText = source
                
                // user
                let addedBy = NSMutableAttributedString(string: "Adăugată de ", attributes: fieldAttr)
                let userNick = NSAttributedString(string: def.userNick, attributes: valueAttr)
                addedBy.append(userNick)
                self.addedByLabel.attributedText = addedBy
                
                // Save button
                self.saveDefinitionButton.setImage(UIImage(systemName: def.saved ? "checkmark.circle.fill" : "square.and.arrow.down"), for: .normal)
            } else {
                self.textView.text = ""
                self.addedByLabel.text = ""
                self.sourceLabel.text = ""
                self.saveDefinitionButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
            }
        }
    }
    
    private let tapGR = UITapGestureRecognizer()
    
    weak var delegate: DefinitionCellPopoverDelegate?
    
    weak var definitionSaverDelegate: DefinitionSaverDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        tapGR.addTarget(self, action: #selector(openPopover(_:)))
        self.textView.addGestureRecognizer(tapGR)
        self.saveDefinitionButton.setTitle("", for: .normal)
    }
    
    @objc fileprivate func openPopover(_ sender: UITapGestureRecognizer) {
        
        guard let def = def,
              let footnotes = def.footnotes else { return }
        
        for range in footnotes.keys {
            let (didTap, rect) = tapGR.didTapAttributedTextInLabel(textView: textView, inRange: range)
            if didTap, let footnote = footnotes[range] {
                delegate?.openPopover(sourceView: self.textView, sourceRect: rect!, footnote: footnote)
            }
        }
    }
}
