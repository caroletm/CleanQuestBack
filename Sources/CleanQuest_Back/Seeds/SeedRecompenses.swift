import Fluent

func seedRecompenses(on db: any Database) async throws {

    struct RecompenseSeed {
        let nom: String
        let categorie: String
        let points: Double
        let descriptionCourte: String
        let descriptionLongue: String
        let descriptionEnCours: String
        let image: String
        var dureeMinutes: Int = 1440 // 24h par défaut
    }

    let recompenses: [RecompenseSeed] = [
        RecompenseSeed(nom: "Chef du film", categorie: "privilege", points: 30,
            descriptionCourte: "Choisis le film.",
            descriptionLongue: "Tu choisis le film ou la série que tout le foyer regarde.",
            descriptionEnCours: "Choix du film de la soirée en cours.",
            image: "clapperboard_1424833.png"),
        RecompenseSeed(nom: "DJ Officiel", categorie: "privilege", points: 20,
            descriptionCourte: "Choisis la musique.",
            descriptionLongue: "Tu contrôles la playlist de la maison pendant une heure.",
            descriptionEnCours: "Playlist de la maison sous contrôle.",
            image: "music_1930581.png", dureeMinutes: 60),
        RecompenseSeed(nom: "Chef du repas", categorie: "privilege", points: 80,
            descriptionCourte: "Choisis le menu.",
            descriptionLongue: "Tu décides du repas du prochain déjeuner ou dîner.",
            descriptionEnCours: "Choix du repas en cours.",
            image: "bandeja-paisa_11590371.png"),
        RecompenseSeed(nom: "Dessert Royal", categorie: "privilege", points: 40,
            descriptionCourte: "Choisis le dessert.",
            descriptionLongue: "Tu choisis le dessert du prochain repas.",
            descriptionEnCours: "Choix du dessert en cours.",
            image: "pudding_12009550.png"),
        RecompenseSeed(nom: "Choix du jeu", categorie: "privilege", points: 30,
            descriptionCourte: "Choisis le jeu.",
            descriptionLongue: "Tu choisis le prochain jeu de société ou jeu vidéo.",
            descriptionEnCours: "Choix du jeu en cours.",
            image: "playing-cards_5558526.png"),
        RecompenseSeed(nom: "Sortie VIP", categorie: "privilege", points: 150,
            descriptionCourte: "Choisis la sortie.",
            descriptionLongue: "Tu décides de la prochaine activité familiale.",
            descriptionEnCours: "Choix de la prochaine sortie en cours.",
            image: "hiking_4516841.png", dureeMinutes: 10080),
        RecompenseSeed(nom: "Canapé VIP", categorie: "privilege", points: 40,
            descriptionCourte: "La meilleure place.",
            descriptionLongue: "La meilleure place du canapé est réservée pour toi.",
            descriptionEnCours: "Meilleure place du canapé réservée.",
            image: "armchair_8033331.png", dureeMinutes: 240),
        RecompenseSeed(nom: "Télécommande", categorie: "privilege", points: 40,
            descriptionCourte: "Tu commandes la TV.",
            descriptionLongue: "Tu gardes la télécommande toute la soirée.",
            descriptionEnCours: "Télécommande réquisitionnée.",
            image: "remote-control_5870135.png", dureeMinutes: 240),
        RecompenseSeed(nom: "Nuit Bonus", categorie: "privilege", points: 180,
            descriptionCourte: "30 min de plus.",
            descriptionLongue: "Tu peux te coucher 30 minutes plus tard (avec accord des parents).",
            descriptionEnCours: "Coucher repoussé de 30 minutes.",
            image: "night_11251996.png", dureeMinutes: 30),
        RecompenseSeed(nom: "Nuit calme", categorie: "privilege", points: 180,
            descriptionCourte: "Le bébé fera sa nuit sans toi.",
            descriptionLongue: "Tu ne te lèves pas cette nuit pour le bébé.",
            descriptionEnCours: "Nuit sans lever pour le bébé.",
            image: "baby-sleep_14777620.png", dureeMinutes: 720),
        RecompenseSeed(nom: "Grasse Matinée", categorie: "privilege", points: 220,
            descriptionCourte: "Dors plus longtemps.",
            descriptionLongue: "Tu profites d'une grasse matinée bien méritée.",
            descriptionEnCours: "Grasse matinée en cours.",
            image: "pillow_2107069.png", dureeMinutes: 720),
        RecompenseSeed(nom: "Jour Pyjama", categorie: "privilege", points: 120,
            descriptionCourte: "Reste en pyjama.",
            descriptionLongue: "Profite d'une journée pyjama à la maison.",
            descriptionEnCours: "Journée pyjama en cours.",
            image: "pijama_2994668.png"),
        RecompenseSeed(nom: "Chef du foyer", categorie: "privilege", points: 200,
            descriptionCourte: "Tu décides.",
            descriptionLongue: "Pendant une journée, tu prends les petites décisions du foyer.",
            descriptionEnCours: "Petites décisions du foyer déléguées.",
            image: "crown_3483028.png"),
        RecompenseSeed(nom: "Petit Déjeuner", categorie: "action", points: 160,
            descriptionCourte: "Petit-déjeuner servi.",
            descriptionLongue: "Un membre du foyer te prépare le petit-déjeuner.",
            descriptionEnCours: "Petit-déjeuner en préparation.",
            image: "waffle_11615187.png"),
        RecompenseSeed(nom: "Chocolat Chaud", categorie: "action", points: 40,
            descriptionCourte: "Boisson préparée.",
            descriptionLongue: "Quelqu'un te prépare un délicieux chocolat chaud.",
            descriptionEnCours: "Chocolat chaud en préparation.",
            image: "chocolate_11590391.png", dureeMinutes: 60),
        RecompenseSeed(nom: "Pop-corn Party", categorie: "action", points: 50,
            descriptionCourte: "Pop-corn offert.",
            descriptionLongue: "Quelqu'un prépare le pop-corn pour la soirée film.",
            descriptionEnCours: "Pop-corn en préparation.",
            image: "popcorn_848998.png", dureeMinutes: 120),
        RecompenseSeed(nom: "Boisson Express", categorie: "action", points: 20,
            descriptionCourte: "Boisson servie.",
            descriptionLongue: "Quelqu'un t'apporte la boisson de ton choix.",
            descriptionEnCours: "Boisson en route.",
            image: "orange-juice_571480.png", dureeMinutes: 30),
        RecompenseSeed(nom: "Massage Flash", categorie: "action", points: 120,
            descriptionCourte: "Massage 10 min.",
            descriptionLongue: "Profite d'un massage de 10 minutes.",
            descriptionEnCours: "Massage en cours.",
            image: "face-massage_11031252.png", dureeMinutes: 10),
        RecompenseSeed(nom: "Lecture VIP", categorie: "action", points: 40,
            descriptionCourte: "Une histoire.",
            descriptionLongue: "Quelqu'un te lit une histoire ou un chapitre.",
            descriptionEnCours: "Lecture en cours.",
            image: "braille_8457951.png", dureeMinutes: 60),
        RecompenseSeed(nom: "Partie Bonus", categorie: "action", points: 60,
            descriptionCourte: "On joue avec toi.",
            descriptionLongue: "Un membre du foyer joue avec toi pendant 30 minutes.",
            descriptionEnCours: "Partie en cours.",
            image: "controller_1975072.png", dureeMinutes: 30),
        RecompenseSeed(nom: "Aide", categorie: "action", points: 100,
            descriptionCourte: "Un coup de main.",
            descriptionLongue: "Quelqu'un t'aide pour la tâche de ton choix pendant 20 minutes.",
            descriptionEnCours: "Coup de main en cours.",
            image: "team-building_12505249.png", dureeMinutes: 20),
        RecompenseSeed(nom: "Coiffure Fun", categorie: "action", points: 50,
            descriptionCourte: "Nouvelle coiffure.",
            descriptionLongue: "Quelqu'un te fait une coiffure amusante.",
            descriptionEnCours: "Coiffure en préparation.",
            image: "woman_7862627.png", dureeMinutes: 60),
        RecompenseSeed(nom: "Dessin Cadeau", categorie: "action", points: 40,
            descriptionCourte: "Un dessin rien que pour toi.",
            descriptionLongue: "Un membre du foyer réalise un dessin personnalisé.",
            descriptionEnCours: "Dessin en création.",
            image: "art_7439494.png"),
        RecompenseSeed(nom: "Compliments", categorie: "action", points: 60,
            descriptionCourte: "Une jolie carte.",
            descriptionLongue: "Reçois une carte personnalisée remplie de compliments.",
            descriptionEnCours: "Carte de compliments en préparation.",
            image: "feedback_11511403.png"),
        RecompenseSeed(nom: "Câlin XXL", categorie: "action", points: 20,
            descriptionCourte: "Un gros câlin.",
            descriptionLongue: "Profite d'un énorme câlin plein de bonne humeur.",
            descriptionEnCours: "C'est l'heure du câlin.",
            image: "heart_5641878.png", dureeMinutes: 1),
        RecompenseSeed(nom: "Compliment Star", categorie: "action", points: 30,
            descriptionCourte: "Compliments garantis.",
            descriptionLongue: "La personne te dit une qualité qu'elle apprécie chez toi.",
            descriptionEnCours: "Compliments en route.",
            image: "star_6024600.png", dureeMinutes: 30),
        RecompenseSeed(nom: "Plateau Télé", categorie: "action", points: 140,
            descriptionCourte: "Repas servi.",
            descriptionLongue: "Quelqu'un prépare ton plateau repas pour la soirée film.",
            descriptionEnCours: "Plateau repas en préparation.",
            image: "romantic-dinner_9028307.png", dureeMinutes: 120),
        RecompenseSeed(nom: "Pause Vaisselle", categorie: "action", points: 180,
            descriptionCourte: "Une vaisselle offerte.",
            descriptionLongue: "Quelqu'un fait exceptionnellement ton prochain tour de vaisselle.",
            descriptionEnCours: "Vaisselle prise en charge.",
            image: "plate_8033362.png", dureeMinutes: 10080),
        RecompenseSeed(nom: "Aide Rangement", categorie: "action", points: 120,
            descriptionCourte: "On t'aide à ranger.",
            descriptionLongue: "Un membre du foyer t'aide à ranger pendant 20 minutes.",
            descriptionEnCours: "Aide au rangement en cours.",
            image: "powder_7040442.png", dureeMinutes: 20),
        RecompenseSeed(nom: "Chef Pâtissier", categorie: "action", points: 180,
            descriptionCourte: "Un gâteau maison.",
            descriptionLongue: "Quelqu'un prépare une gourmandise maison pour le foyer.",
            descriptionEnCours: "Gourmandise maison en préparation.",
            image: "cake_5976416.png"),
        RecompenseSeed(nom: "Moment Ensemble", categorie: "action", points: 100,
            descriptionCourte: "30 minutes ensemble.",
            descriptionLongue: "Choisis une activité à partager avec un membre du foyer pendant 30 minutes.",
            descriptionEnCours: "Moment à partager en cours.",
            image: "pinwheel_6161246.png", dureeMinutes: 30),
        RecompenseSeed(nom: "Danse Victory", categorie: "action", points: 40,
            descriptionCourte: "Danse obligatoire.",
            descriptionLongue: "Choisis quelqu'un qui doit faire une danse de la victoire pendant 30 secondes.",
            descriptionEnCours: "Place à la danse !",
            image: "pasodoble_11986338.png", dureeMinutes: 5),
        RecompenseSeed(nom: "Champion", categorie: "privilege", points: 60,
            descriptionCourte: "Ovation du foyer.",
            descriptionLongue: "Tout le foyer te félicite et t'applaudit pour ton effort.",
            descriptionEnCours: "Moment de gloire 🏆",
            image: "trophy_6689184.png", dureeMinutes: 60),
        RecompenseSeed(nom: "Merci Géant", categorie: "privilege", points: 50,
            descriptionCourte: "Reconnaissance du foyer.",
            descriptionLongue: "Chaque membre du foyer prend un moment pour te dire merci pour quelque chose que tu fais bien.",
            descriptionEnCours: "Le foyer dit merci 💛",
            image: "thank-you_3158981.png"),
        RecompenseSeed(nom: "Majordome", categorie: "action", points: 250,
            descriptionCourte: "Service Premium",
            descriptionLongue: "Choisis un membre du foyer qui devient ton majordome pendant 24 heures et t'aide pour tes petites demandes du quotidien",
            descriptionEnCours: "Majordome en service.",
            image: "waiter_2766039.png"),
    ]

    // Cache des catégories pour éviter une requête par récompense
    var categoriesParNom: [String: CategorieRecompense] = [:]

    for seed in recompenses {
        let categorie: CategorieRecompense
        if let deja = categoriesParNom[seed.categorie] {
            categorie = deja
        } else {
            guard let trouvee = try await CategorieRecompense.query(on: db)
                .filter(\.$nom == seed.categorie)
                .first()
            else { continue }
            categoriesParNom[seed.categorie] = trouvee
            categorie = trouvee
        }
        
        if let existante = try await Recompense.query(on: db)
            .filter(\.$nom == seed.nom)
            .first() {
            var modifiee = false
            if existante.dureeMinutes != seed.dureeMinutes {
                existante.dureeMinutes = seed.dureeMinutes
                modifiee = true
            }
            if existante.descriptionEnCours != seed.descriptionEnCours {
                existante.descriptionEnCours = seed.descriptionEnCours
                modifiee = true
            }
            if modifiee {
                try await existante.save(on: db)
            }
        } else {
            try await Recompense(
                nom: seed.nom,
                image: seed.image,
                points: seed.points,
                descriptionLongue: seed.descriptionLongue,
                descriptionCourte: seed.descriptionCourte,
                descriptionEnCours: seed.descriptionEnCours,
                dureeMinutes: seed.dureeMinutes,
                categorieId: categorie.id!
            ).save(on: db)
        }
    }
}
