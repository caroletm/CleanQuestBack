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
            ("Panier", "basket_6197238.png"),
            ("Bain", "bath_1010828.png"),
            ("Bain 2", "bath_14109179.png"),
            ("Serviette de plage", "beach-towel_1891379.png"),
            ("Vélo", "bicycle_7803890.png"),
            ("Câble", "cable_11939573.png"),
            ("Voiture", "car_2880473.png"),
            ("Voiture 2", "car_6147997.png"),
            ("Chat", "cat_9288621.png"),
            ("Litière chat", "cat-box_1581602.png"),
            ("Enfants", "children_2073048.png"),
            ("Nettoyage", "clean_1748937.png"),
            ("Nettoyage 2", "cleaning_8033437.png"),
            ("Vêtements", "clothes_3300358.png"),
            ("Vêtements 2", "clothes_6683925.png"),
            ("Canapé", "couch_11645978.png"),
            ("Danse", "dance_15944491.png"),
            ("Bureau", "desk_8495611.png"),
            ("Chien", "dog_8183292.png"),
            ("Lit double", "double-bed_1074190.png"),
            ("Séchage", "drying_7040438.png"),
            ("Éco-énergie", "eco-energy_12416139.png"),
            ("Réfrigérateur", "fridge_2478388.png"),
            ("Poubelle verre", "glass-bin_3300706.png"),
            ("Croissance", "growth_1012258.png"),
            ("Auberge", "hostel_5558495.png"),
            ("Fer à repasser", "iron_1010834.png"),
            ("Fer à repasser 2", "iron_1748939.png"),
            ("Lessive", "laundry_7459130.png"),
            ("Panier à linge", "laundry-basket_2523641.png"),
            ("Tondeuse", "lawn-mower_3428198.png"),
            ("Feuille", "leaf_2204401.png"),
            ("Feuilles", "leaves_12053698.png"),
            ("Faire le lit", "make-bed_6683869.png"),
            ("Micro-ondes", "microwave_2457558.png"),
            ("Four", "oven_5870357.png"),
            ("Porte-papier", "paper-holder_9406830.png"),
            ("Pinata", "pinata_5976030.png"),
            ("Assiette", "plate_8033362.png"),
            ("Pyramide", "pyramid_1362059.png"),
            ("Exigences", "requirement_14752474.png"),
            ("Chemise", "shirt_7040290.png"),
            ("Chaussures", "shoes_2912735.png"),
            ("Douche", "shower_1864095.png"),
            ("Sofa", "sofa_6974140.png"),
            ("Soupe", "soup_4830808.png"),
            ("Éponge", "sponge_8962557.png"),
            ("Spray", "spray_2269870.png"),
            ("Grand nettoyage", "spring-cleaning_2658050.png"),
            ("Rangement", "store_827866.png"),
            ("Cuisinière", "stove_823255.png"),
            ("Supermarché", "supermarket_3300431.png"),
            ("SUV", "suv-car_6558135.png"),
            ("T-shirt", "t-shirt_2552377.png"),
            ("Télévision", "television_8889428.png"),
            ("Toilettes", "toilet_1074180.png"),
            ("Toilettes 2", "toilet_5685509.png"),
            ("Papier toilette", "toilet-paper_1074183.png"),
            ("Poubelle", "trash-bin_7617982.png"),
            ("Arbre", "tree_1012791.png"),
            ("Arbre 2", "tree_1662687.png"),
            ("Aspirateur", "vacuum_1010268.png"),
            ("Promener le chien", "walking-dog_9012065.png"),
            ("Faire la vaisselle", "washing-dishes_6974103.png"),
            ("Lave-linge", "washing-machine_999949.png"),
            ("Fouet", "whisk_12242615.png"),
            ("Fenêtre", "window_2523637.png"),
            ("Fenêtre 2", "window_2523658.png"),
            ("Fenêtre 3", "window_6026172.png"),
            ("Nettoyant fenêtre", "window-cleaner_1748923.png"),
        ]

        for icone in icones {
            try await Icone(nom: icone.nom, nomFichier: icone.nomFichier).save(on: db)
        }
    }

    func revert(on db: any Database) async throws {
        try await Icone.query(on: db).delete()
    }
}
