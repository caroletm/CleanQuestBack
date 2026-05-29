-- =============================================================================
-- Purge automatique des occurrences de tâches de plus de 2 mois
-- =============================================================================
-- Pendant de la génération (côté Swift). La rétention de 2 mois permet à
-- l'utilisateur de consulter dans son suivi la réalisation de ses tâches sur
-- le mois écoulé à partir de la date du jour.
--
-- À exécuter dans MySQL Workbench, connecté à la base CleanQuest.
-- Ce script ne s'exécute pas tout seul : il met en place un EVENT MySQL qui,
-- lui, tournera tous les jours côté base de données.
-- =============================================================================

USE CleanQuest;

-- -----------------------------------------------------------------------------
-- 1. Activer le planificateur d'événements
-- -----------------------------------------------------------------------------
-- EN LOCAL (XAMPP, droits root) : la commande ci-dessous suffit, mais elle est
-- réinitialisée à OFF au redémarrage de MySQL. Pour la rendre permanente,
-- ajouter `event_scheduler = ON` sous [mysqld] dans my.cnf / my.ini.
--
-- EN PROD SUR AZURE (Azure Database for MySQL) : `SET GLOBAL` échouera (pas de
-- privilège SUPER en managé). Activer à la place le paramètre serveur
-- `event_scheduler` = ON depuis le portail Azure (Server parameters), ce qui
-- est permanent. Vérifier l'état avec : SHOW VARIABLES LIKE 'event_scheduler';
-- (ON = actif, OFF = activable, DISABLED = verrouillé -> passer au plan B).

SET GLOBAL event_scheduler = ON;

-- -----------------------------------------------------------------------------
-- 2. Créer l'event de purge quotidienne
-- -----------------------------------------------------------------------------
-- S'exécute tous les jours à 03h00 (première exécution : le lendemain de la
-- création) et supprime toute occurrence dont la datePlanifiee est antérieure
-- à maintenant - 2 mois.

CREATE EVENT IF NOT EXISTS purge_occurrences_anciennes
ON SCHEDULE
    EVERY 1 DAY
    STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 3 HOUR)
COMMENT 'Supprime les occurrences de plus de 2 mois (rétention historique de suivi)'
DO
    DELETE FROM occurence_tache
    WHERE datePlanifiee < NOW() - INTERVAL 2 MONTH;

-- -----------------------------------------------------------------------------
-- 3. Vérifier / gérer l'event (à lancer à la demande)
-- -----------------------------------------------------------------------------
-- SHOW VARIABLES LIKE 'event_scheduler';            -- le planificateur est-il actif ?
-- SHOW EVENTS FROM CleanQuest;                       -- l'event et sa prochaine exécution
-- ALTER EVENT purge_occurrences_anciennes DISABLE;   -- mettre en pause
-- ALTER EVENT purge_occurrences_anciennes ENABLE;    -- réactiver
-- DROP EVENT IF EXISTS purge_occurrences_anciennes;  -- supprimer

-- -----------------------------------------------------------------------------
-- Plan B (si event_scheduler = DISABLED, impossible à activer) : cron système
-- lançant la même requête, p. ex. tous les jours à 03h00 :
--   0 3 * * * mysql -h HOST -u USER -pMDP CleanQuest \
--     -e "DELETE FROM occurence_tache WHERE datePlanifiee < NOW() - INTERVAL 2 MONTH;"
-- -----------------------------------------------------------------------------
