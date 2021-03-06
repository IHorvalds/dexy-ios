//
//  DefinitionLookup.swift
//  Dexy
//
//  Created by Tudor Croitoru on 13/02/2021.
//

import SwiftyJSON
import UIKit

class DefinitionLookup {
    
    struct Definition: Hashable {
        let id: Int
        private let internalRep: String
        let formattedDefinition: NSAttributedString
        var saved: Bool = false
        let userNick: String
        let sourceName: String
        let createdDate: Date
        let modifiedDate: Date
        let word: String
        var footnotes: [NSRange:String]? = [:]
        
        init?(json: JSON, word: String) {
            self.word = word
            
            if let jsonId = json["id"].string,
               let id = Int(jsonId) {
                self.id = id
            } else {
                return nil
            }
            
            if let jsonInternalRep = json["internalRep"].string {
                self.internalRep = jsonInternalRep
                self.formattedDefinition = jsonInternalRep.formatString(baseFont: .systemFont(ofSize: 14.0), footnotes: &footnotes)
            } else {
                return nil
            }
            
            if let jsonUser = json["userNick"].string {
                self.userNick = jsonUser
            } else {
                return nil
            }
            
            if let jsonSource = json["sourceName"].string {
                self.sourceName = jsonSource
            } else {
                return nil
            }
            
            if let jsonCreated = json["createDate"].string,
               let seconds = Double(jsonCreated) {
                self.createdDate = Date(timeIntervalSince1970: seconds)
            } else {
                return nil
            }
            
            if let jsonMod = json["modDate"].string,
               let seconds = Double(jsonMod) {
                self.modifiedDate = Date(timeIntervalSince1970: seconds)
            } else {
                return nil
            }
        }
        
        init(id: Int, internalRep: String, saved: Bool, userNick: String, sourceName: String, createdDate: Date, modifiedDate: Date, word: String) {
            self.id = id
            self.internalRep = internalRep
            self.formattedDefinition = internalRep.formatString(baseFont: .systemFont(ofSize: 14.0), footnotes: &footnotes)
            self.saved = saved
            self.userNick = userNick
            self.sourceName = sourceName
            self.createdDate = createdDate
            self.modifiedDate = modifiedDate
            self.word = word
        }
        
        func getInternalRepresentation() -> String {
            self.internalRep
        }
    }
    
    let id: UUID
    let word: String
    var definitions: [Definition] = []
    
    init?(data: Data) {
        let json = try? JSON(data: data)
        
        if let json = json {
            if let jsonWord = json["word"].string {
                word = jsonWord
            } else {
                return nil
            }
            
            if let jsonDefinitions = json["definitions"].array {
                for def in jsonDefinitions {
                    if let definition = Definition(json: def, word: self.word) {
                        self.definitions.append(definition)
                    }
                }
            } else {
                return nil
            }
            
            self.id = UUID()
            
        } else {
            return nil
        }
    }
}

extension DefinitionLookup {
    private static let _dictionaries = [
        ""                      : "Toate dic??ionarele",
        "dex09"                 : "(DEX '09) Dic??ionarul explicativ al limbii rom??ne (edi??ia a II-a rev??zut?? ??i ad??ugit??)",
        "doom2"                 : "(DOOM 2) Dic??ionar ortografic, ortoepic ??i morfologic al limbii rom??ne, edi??ia a II-a rev??zut?? ??i ad??ugit??",
        "sinonime"              : "(Sinonime) Dic??ionar de sinonime",
        "das"                   : "(DAS) Dic??ionar analogic ??i de sinonime al limbii rom??ne",
        "antonime"              : "(Antonime) Dic??ionar de antonime",
        "dlr"                   : "(DLR) Dic??ionar al limbii rom??ne (Dic??ionarul Academiei)",
        "dex16"                 : "(DEX '16) Dic??ionarul explicativ al limbii rom??ne (edi??ia a II-a rev??zut?? ??i ad??ugit??)",
        "dex12"                 : "(DEX '12) Dic??ionarul explicativ al limbii rom??ne (edi??ia a II-a rev??zut?? ??i ad??ugit??)",
        "mda2"                  : "(MDA2) Micul dic??ionar academic, edi??ia a II-a",
        "DEXI"                  : "(DEXI) Dic??ionar explicativ ilustrat al limbii rom??ne",
        "dex"                   : "(DEX '98) Dic??ionarul explicativ al limbii rom??ne, edi??ia a II-a",
        "dex96"                 : "(DEX '96) Dic??ionarul explicativ al limbii rom??ne, edi??ia a II-a",
        "dexs88"                : "(DEX-S) Supliment la Dic??ionarul explicativ al limbii rom??ne",
        "dex84"                 : "(DEX '84) Dic??ionarul explicativ al limbii rom??ne",
        "dex75"                 : "(DEX '75) Dic??ionarul explicativ al limbii rom??ne",
        "dlrlc"                 : "(DLRLC) Dic??ionarul limbii rom??ne literare contemporane",
        "dlrm"                  : "(DLRM) Dic??ionarul limbii rom??ne moderne",
        "mda"                   : "(MDA) Micul dic??ionar academic",
        "dor"                   : "(DOR) Marele dic??ionar ortografic al limbii rom??ne",
        "do"                    : "(Ortografic) Dic??ionar ortografic al limbii rom??ne",
        "doom"                  : "(DOOM) Dic??ionar ortografic, ortoepic ??i morfologic al limbii rom??ne",
        "dmlr"                  : "(DMLR) Dictionnaire morphologique de la langue roumaine",
        "intern"                : "(dexonline) Dic??ionar intern dexonline",
        "DGS"                   : "(DGS) Dic??ionar General de Sinonime al Limbii Rom??ne",
        "Sinonime82"            : "(Sinonime82) Dic??ionarul de sinonime al limbii rom??ne",
        "dn"                    : "(DN) Dic??ionar de neologisme",
        "mdn08"                 : "(MDN '08) Marele dic??ionar de neologisme (edi??ia a 10-a, rev??zut??, augmentat?? ??i actualizat??)",
        "mdn00"                 : "(MDN '00) Marele dic??ionar de neologisme",
        "dcr2"                  : "(DCR2) Dic??ionar de cuvinte recente, edi??ia a II-a",
        "dlrc"                  : "(DLRC) Dic??ionar al limbii rom??ne contemporane",
        "der"                   : "(DER) Dic??ionarul etimologic rom??n",
        "ger"                   : "(GER) Etimologii rom??ne??ti",
        "gaer"                  : "(GAER) Alte etimologii rom??ne??ti",
        "dei"                   : "(DEI) Dic??ionar enciclopedic ilustrat",
        "nodex"                 : "(NODEX) Noul dic??ionar explicativ al limbii rom??ne",
        "dlrlv"                 : "(DLRLV) Dic??ionarul limbii rom??ne literare vechi (1640-1780) - Termeni regionali",
        "dar"                   : "(DAR) Dic??ionar de arhaisme ??i regionalisme",
        "dsl"                   : "(DSL) Dic??ionar General de ??tiin??e. ??tiin??e ale limbii",
        "mitologic??"            : "(Mitologic) Mic dic??ionar mitologic greco-roman",
        "dulr6"                 : "(????ineanu, ed. VI) Dic??ionar universal al limbei rom??ne, edi??ia a VI-a",
        "scriban"               : "(Scriban) Dic??ionaru limbii rom??ne??ti",
        "dgl"                   : "(DGL) Dic??ionar al gre??elilor de limb??",
        "dps"                   : "(Petro-Sedim) Dic??ionar de termeni ??? Sedimentologie - Petrologie sedimentar?? - Sisteme depozi??ionale",
        "gta"                   : "(GTA) Glosar de termeni aviatici",
        "dge"                   : "(DGE) Dic??ionar gastronomic explicativ",
        "dtm"                   : "(DTM) Dic??ionar de termeni muzicali",
        "religios"              : "(D.Religios) Dic??ionar religios",
        "argou"                 : "(Argou) Dic??ionar de argou al limbii rom??ne",
        "dram15"                : "(DRAM 2015) Dic??ionar de regionalisme ??i arhaisme din Maramure??, edi??ia a doua",
        "dram"                  : "(DRAM) Dic??ionar de regionalisme ??i arhaisme din Maramure??",
        "de"                    : "(DE) Dic??ionar enciclopedic",
        "dtl"                   : "(DTL) Dic??ionar de termeni lingvistici",
        "dmg"                   : "(DMG) Dic??ionar de matematici generale",
        "don"                   : "(Onomastic) Dic??ionar Onomastic Rom??nesc",
        "CADE"                  : "(CADE) Dic??ionarul enciclopedic ilustrat",
        "DifSem"                : "(DifSem) Dificult????i semantice",
        "neoficial"             : "(Neoficial) Defini??ii ale unor cuvinte care nu exist?? ??n alte dic??ionare",
        "dendrofloricol"        : "(DFL) Dic??ionar dendrofloricol",
        "dlra"                  : "(DLRA) Dic??ionar al limbii rom??ne actuale (edi??ia a II-a rev??zut?? ??i ad??ugit??)",
        "dets"                  : "(DETS) Dic??ionar etimologic de termeni ??tiin??ifici",
        "dfs"                   : "(DFS) Dic??ionarul figurilor de stil",
        "dan"                   : "(DAN) Dic??ionarul Actualizat de Neologisme",
        "lex"                   : "(Legisla??ie) Legisla??ia Rom??niei",
        "psi"                   : "(psi) Dic??ionar de psihologie",
        "mdo"                   : "(MDO) Mic Dic??ionar Ortografic",
        "dex-scolar"            : "(DEX-??colar) Dic??ionar explicativ ??colar",
        "ivo3"                  : "(IVO-III) ??ndreptar ??i vocabular ortografic (edi??ia a III-a, rev??zut?? ??i completat??)",
        "meo"                   : "(MEO) Mic?? Enciclopedie Onomastic??",
        "din"                   : "(DIN) Dic??ionar normativ al limbii rom??ne ortografic, ortoepic, morfologic ??i practic",
        "terminologie-literara" : "(MDTL) Mic dic??ionar ??ndrum??tor ??n terminologia literar??"
    ]
    
    public static let dictionaryUrls: NSOrderedSet = {
        return NSOrderedSet(array: Array(_dictionaries.keys.sorted()))
    }()
    
    public static func dictionaryName(url: String) -> String {
        _dictionaries[url] ?? ""
    }
}
