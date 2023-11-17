//
//  MTGCard.swift
//  MobComp_MagicTheGathering_ElyoraDior
//
//  Created by MacBook Pro on 10/11/23.
//

// MTGCard.swift
import Foundation

struct MTGCard: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var type_line: String
    var oracle_text: String
    var image_uris: ImageURIs?
    var legalities: [String: String]
    var prices: Prices?
    var mana_cost: String?
    var collector_number: String? 
    
    // Define other properties as needed based on your JSON structure
    
    struct ImageURIs: Codable {
        var small: String?
        var normal: String?
        var large: String?
        var png: String?
        var art_crop: String?
        var border_crop: String?
        // Add other image URL properties if needed
    }
    
    struct Prices: Codable {
        var usd: String?
        var usd_foil: String?
        var usd_etched: String?
        var eur: String?
        var eur_foil: String?
        var tix: String?
    }

    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: MTGCard, rhs: MTGCard) -> Bool {
            return lhs.id == rhs.id
        }
    
}

struct MTGCardList: Codable {
    var object: String
    var total_cards: Int
    var has_more: Bool
    var data: [MTGCard]
}


