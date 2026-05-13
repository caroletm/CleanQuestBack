//
//  SeedIcones.swift
//  CleanQuest_Back
//
//  Created by caroletm on 13/05/2026.
//

import Fluent

struct SeedIcones: AsyncMigration {
    func prepare(on db: any Database) async throws {
        let icones: [(nom: String, nomFichier: String)] = [
            ("Panier", "basket_6197238.svg"),
            ("Bain", "bath_1010828.svg"),
            ("Bain 2", "bath_14109179.svg"),
            ("Serviette de plage", "beach-towel_1891379.svg"),
            ("Vélo", "bicycle_7803890.svg"),
            ("Câble", "cable_11939573.svg"),
            ("Voiture", "car_2880473.svg"),
            ("Voiture 2", "car_6147997.svg"),
            ("Chat", "cat_9288621.svg"),
            ("Litière chat", "cat-box_1581602.svg"),
            ("Enfants", "children_2073048.svg"),
            ("Nettoyage", "clean_1748937.svg"),
            ("Nettoyage 2", "cleaning_8033437.svg"),
            ("Vêtements", "clothes_3300358.svg"),
            ("Vêtements 2", "clothes_6683925.svg"),
            ("Canapé", "couch_11645978.svg"),
            ("Danse", "dance_15944491.svg"),
            ("Bureau", "desk_8495611.svg"),
            ("Chien", "dog_8183292.svg"),
            ("Lit double", "double-bed_1074190.svg"),
            ("Séchage", "drying_7040438.svg"),
            ("Éco-énergie", "eco-energy_12416139.svg"),
            ("Réfrigérateur", "fridge_2478388.svg"),
            ("Poubelle verre", "glass-bin_3300706.svg"),
            ("Croissance", "growth_1012258.svg"),
            ("Auberge", "hostel_5558495.svg"),
            ("Fer à repasser", "iron_1010834.svg"),
            ("Fer à repasser 2", "iron_1748939.svg"),
            ("Lessive", "laundry_7459130.svg"),
            ("Panier à linge", "laundry-basket_2523641.svg"),
            ("Tondeuse", "lawn-mower_3428198.svg"),
            ("Feuille", "leaf_2204401.svg"),
            ("Feuilles", "leaves_12053698.svg"),
            ("Faire le lit", "make-bed_6683869.svg"),
            ("Micro-ondes", "microwave_2457558.svg"),
            ("Four", "oven_5870357.svg"),
            ("Porte-papier", "paper-holder_9406830.svg"),
            ("Pinata", "pinata_5976030.svg"),
            ("Assiette", "plate_8033362.svg"),
            ("Pyramide", "pyramid_1362059.svg"),
            ("Exigences", "requirement_14752474.svg"),
            ("Chemise", "shirt_7040290.svg"),
            ("Chaussures", "shoes_2912735.svg"),
            ("Douche", "shower_1864095.svg"),
            ("Sofa", "sofa_6974140.svg"),
            ("Soupe", "soup_4830808.svg"),
            ("Éponge", "sponge_8962557.svg"),
            ("Spray", "spray_2269870.svg"),
            ("Grand nettoyage", "spring-cleaning_2658050.svg"),
            ("Rangement", "store_827866.svg"),
            ("Cuisinière", "stove_823255.svg"),
            ("Supermarché", "supermarket_3300431.svg"),
            ("SUV", "suv-car_6558135.svg"),
            ("T-shirt", "t-shirt_2552377.svg"),
            ("Télévision", "television_8889428.svg"),
            ("Toilettes", "toilet_1074180.svg"),
            ("Toilettes 2", "toilet_5685509.svg"),
            ("Papier toilette", "toilet-paper_1074183.svg"),
            ("Poubelle", "trash-bin_7617982.svg"),
            ("Arbre", "tree_1012791.svg"),
            ("Arbre 2", "tree_1662687.svg"),
            ("Aspirateur", "vacuum_1010268.svg"),
            ("Promener le chien", "walking-dog_9012065.svg"),
            ("Faire la vaisselle", "washing-dishes_6974103.svg"),
            ("Lave-linge", "washing-machine_999949.svg"),
            ("Fouet", "whisk_12242615.svg"),
            ("Fenêtre", "window_2523637.svg"),
            ("Fenêtre 2", "window_2523658.svg"),
            ("Fenêtre 3", "window_6026172.svg"),
            ("Nettoyant fenêtre", "window-cleaner_1748923.svg"),
        ]

        for icone in icones {
            try await Icone(nom: icone.nom, nomFichier: icone.nomFichier).save(on: db)
        }
    }

    func revert(on db: any Database) async throws {
        try await Icone.query(on: db).delete()
    }
}
