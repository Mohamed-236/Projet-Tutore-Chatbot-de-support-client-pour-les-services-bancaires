SELECT* FROM faq;
DELETE FROM faq;
TRUNCATE TABLE faq RESTART IDENTITY; --netoyage de la table faq et remetre le compteur a 1

TRUNCATE TABLE carte RESTART IDENTITY;

SELECT * FROM carte;

-- 1️⃣ Table UTILISATEUR
CREATE TABLE utilisateur (
    id_user SERIAL PRIMARY KEY,                          -- ID unique auto-incrémenté
    nom_user VARCHAR(100) NOT NULL,                      -- Nom du client / conseiller
    prenom_user VARCHAR(100) NOT NULL,                   -- Prénom
    email_user VARCHAR(100) NOT NULL UNIQUE,            -- Email unique pour login
    mot_de_passe VARCHAR(100) NOT NULL,                 -- Mot de passe hashé
    tel_user VARCHAR(100) NOT NULL,                     -- Téléphone
    adress_user VARCHAR(100) NOT NULL,                  -- Adresse
    type_user VARCHAR(50) NOT NULL,                     -- Type : 'client' ou 'conseiller'
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP   -- Date + heure de création
);

-- 2️⃣ Table COMPTE
CREATE TABLE compte (
    id_compte SERIAL PRIMARY KEY,                        -- ID unique de compte
    id_user INT NOT NULL,                                 -- Référence vers l'utilisateur
    numero_compte VARCHAR(100) NOT NULL UNIQUE,          -- Numéro de compte unique
    type_compte VARCHAR(50) NOT NULL,                    -- Type : 'courant', 'épargne', etc.
    date_ouverture DATE NOT NULL,                         -- Date d'ouverture
    solde_compte NUMERIC(15,2) NOT NULL,                 -- Solde avec décimales
    statut_compte VARCHAR(50) NOT NULL,                  -- Statut : actif, bloqué, etc.
    FOREIGN KEY (id_user) REFERENCES utilisateur(id_user)  -- Lien avec la table utilisateur
);

UPDATE compte
SET solde_compte = 5000000.00
WHERE id_compte = 1;



-- 3️⃣ Table TRANSACTION
CREATE TABLE trans_client (
    id_transaction SERIAL PRIMARY KEY,                   -- ID unique de transaction
    id_compte INT NOT NULL,                               -- Référence au compte concerné
    type_transaction VARCHAR(50) NOT NULL,               -- Débit, crédit, virement, etc.
    montant_transaction NUMERIC(15,2) NOT NULL,          -- Montant de la transaction
    date_transaction TIMESTAMP NOT NULL,                 -- Date + heure
    statut_transaction VARCHAR(50) NOT NULL,            -- Statut : réussi, échoué, en attente
    est_suspecte BOOLEAN DEFAULT FALSE,                  -- Marque si transaction suspecte
    FOREIGN KEY (id_compte) REFERENCES compte(id_compte)  -- Lien vers le compte
);
ALTER TABLE trans_client
ADD COLUMN id_compte_dest INT NULL REFERENCES compte(id_compte);

ALTER TABLE trans_client
ALTER COLUMN date_transaction SET DEFAULT CURRENT_TIMESTAMP;


-- 4️⃣ Table INTERACTION
CREATE TABLE interaction (
    id_interaction SERIAL PRIMARY KEY,                  -- ID unique
    id_user INT NOT NULL,                                -- Utilisateur qui a posé la question
    question_user VARCHAR(255),                          -- Question posée
    reponse_chatbot VARCHAR(255),                        -- Réponse donnée par le chatbot
    date_interaction TIMESTAMP DEFAULT CURRENT_TIMESTAMP,-- Date + heure interaction
    est_suspecte BOOLEAN DEFAULT FALSE,                  -- Interaction suspecte
    FOREIGN KEY (id_user) REFERENCES utilisateur(id_user)
);

ALTER TABLE interaction
ADD COLUMN id_conversation INT;
--gerer les conversation
CREATE TABLE conversation (
    id_conversation SERIAL PRIMARY KEY,
    id_user INT NOT NULL,
    titre VARCHAR(255) DEFAULT 'Nouvelle conversation',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_user) REFERENCES utilisateur(id_user)
);





-- 5️⃣ Table SUSPICION
CREATE TABLE suspicion (
    id_suspicion SERIAL PRIMARY KEY,                     -- ID unique
    id_transaction INT NOT NULL,                          -- Référence à la transaction suspecte
    date_suspicion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Date + heure suspicion
    raison_suspicion TEXT NOT NULL,                      -- Description de la suspicion
    niveau_risque VARCHAR(50) NOT NULL,                  -- Faible, moyen, élevé
    analyste_humain VARCHAR(100),                        -- Nom du conseiller ou analyste (facultatif)
    FOREIGN KEY (id_transaction) REFERENCES trans_client(id_transaction)
);

-- 6️⃣ Table FAQ
CREATE TABLE faq (
    id_faq SERIAL PRIMARY KEY,                            -- ID unique FAQ
    question_faq VARCHAR(255) NOT NULL,                  -- Question fréquente
    reponse_faq TEXT NOT NULL                             -- Réponse, texte long
);




-- 7  Table carte BANCAIRE
CREATE TABLE carte (
    id_carte SERIAL PRIMARY KEY,
    id_compte INT REFERENCES compte(id_compte),
    numero_carte VARCHAR(20) UNIQUE NOT NULL,
    type_carte VARCHAR(20), -- Visa, MasterCard, etc
    statut_carte VARCHAR(20) DEFAULT 'active', -- active, bloquee, remplacee
    date_expiration DATE
);



--insertion

-- Utilisateurs
INSERT INTO utilisateur (nom_user, prenom_user, email_user, mot_de_passe, tel_user, adress_user, type_user)
VALUES
('Kone','Moussa','moussa.kone1@mail.com','pass123','700000001','Ouagadougou','client'),
('Traore','Awa','awa.traore2@mail.com','pass123','700000002','Bobo-Dioulasso','client'),
('Ouattara','Issa','issa.ouattara3@mail.com','pass123','700000003','Ouagadougou','client'),
('Diarra','Fatou','fatou.diarra4@mail.com','pass123','700000004','Koudougou','client'),
('Zongo','Oumar','oumar.zongo5@mail.com','pass123','700000005','Ouagadougou','client'),
('Kaboré','Salif','salif.kabore6@mail.com','pass123','700000006','Bobo-Dioulasso','client'),
('Coulibaly','Mariama','mariama.coulibaly7@mail.com','pass123','700000007','Ouagadougou','client'),
('Sanou','Abdoulaye','abdoulaye.sanou8@mail.com','pass123','700000008','Banfora','client'),
('Traoré','Mariam','mariam.traore9@mail.com','pass123','700000009','Ouagadougou','client'),
('Kinda','Adama','adama.kinda10@mail.com','pass123','700000010','Bobo-Dioulasso','client'),
-- 10 conseillers
('Ouédraogo','Jean','jean.ouedraogo11@mail.com','pass123','700000011','Ouagadougou','conseiller'),
('Sawadogo','Claire','claire.sawadogo12@mail.com','pass123','700000012','Bobo-Dioulasso','conseiller'),
('Kaboré','Emmanuel','emmanuel.kabore13@mail.com','pass123','700000013','Ouagadougou','conseiller'),
('Diarra','Aïcha','aicha.diarra14@mail.com','pass123','700000014','Koudougou','conseiller'),
('Sanou','Ousmane','ousmane.sanou15@mail.com','pass123','700000015','Banfora','conseiller');



--

INSERT INTO trans_client (id_compte, type_transaction, montant_transaction, date_transaction, statut_transaction, est_suspecte)
VALUES
(1,'debit',20000,'2025-10-01 10:00:00','réussi',FALSE),
(1,'credit',50000,'2025-10-02 15:30:00','réussi',FALSE),
(2,'debit',10000,'2025-10-03 11:00:00','réussi',FALSE),
(3,'credit',25000,'2025-10-04 09:00:00','réussi',FALSE),
(4,'debit',5000,'2025-10-05 14:00:00','réussi',FALSE),
(5,'credit',40000,'2025-10-06 16:30:00','réussi',FALSE),
(6,'debit',30000,'2025-10-07 13:00:00','réussi',FALSE),
(7,'credit',15000,'2025-10-08 10:45:00','réussi',FALSE),
(8,'debit',5000,'2025-10-09 12:15:00','réussi',FALSE),
(9,'credit',10000,'2025-10-10 09:30:00','réussi',FALSE),
-- Ajoute d'autres transactions pour arriver à 100 lignes
(10,'debit',20000,'2025-10-11 14:00:00','réussi',FALSE);





--Insertion des donnees dans faq

TRUNCATE TABLE faq RESTART IDENTITY;


--DONNEES FICTIVES POUR LA TABLE COMPTES

INSERT INTO carte (id_compte, numero_carte, type_carte, date_expiration, statut_carte)
VALUES
(1, '5312 8945 1203 4478', 'Mastercard', '2027-05-01', 'active'),
(2, '4539 2201 9987 1123', 'Visa',       '2026-09-01', 'active'),
(3, '5487 3345 9988 2210', 'Mastercard', '2027-03-01', 'active'),
(4, '4716 8890 3344 5522', 'Visa',       '2028-01-01', 'active'),
(5, '5204 7712 6654 9931', 'Mastercard', '2026-12-01', 'active'),
(6, '4023 5678 9033 1122', 'Visa',       '2027-11-01', 'active'),
(7, '5356 9981 0022 5544', 'Mastercard', '2027-06-01', 'active'),
(8, '4532 1177 8899 0044', 'Visa',       '2026-04-01', 'active'),
(9, '5310 6654 7721 9900', 'Mastercard', '2028-02-01', 'active'),
(10,'4718 3344 5566 7788', 'Visa',       '2027-09-01', 'active');


SELECT * FROM compte





--Modifiaction supplementaire

-- 1) ajouter id_analyste (FK vers utilisateur)
ALTER TABLE suspicion
ADD COLUMN id_analyste INT NULL REFERENCES utilisateur(id_user);

-- 2) remplacer le champ texte analyste_humain si présent
-- (si tu as déjà analyste_humain, on le retire)
ALTER TABLE suspicion
DROP COLUMN IF EXISTS analyste_humain;

-- 3) ajouter statut_analyse et commentaire
ALTER TABLE suspicion
ADD COLUMN statut_analyse VARCHAR(50) DEFAULT 'en_attente';

ALTER TABLE suspicion
ADD COLUMN commentaire TEXT;

-- 4) index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_suspicion_date ON suspicion(date_suspicion DESC);






INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment ouvrir un compte bancaire ?', 'Vous pouvez ouvrir un compte en ligne ou en agence en présentant une pièce d’identité, un justificatif de domicile et une photo d’identité.'),
('Quels sont les types de comptes disponibles ?', 'Nous proposons des comptes courants, des comptes épargne et des comptes professionnels.'),
('Quels documents sont nécessaires pour ouvrir un compte ?', 'Une pièce d’identité valide, un justificatif de domicile et une photo récente.'),
('Combien de temps faut-il pour activer un compte ?', 'L’activation est généralement effective dans les 24 à 48 heures après vérification des documents.'),
('Comment consulter le solde de mon compte ?', 'Vous pouvez consulter votre solde depuis l’application mobile, le site web ou un distributeur automatique.'),
('Comment fermer mon compte bancaire ?', 'Il suffit d’adresser une demande écrite à votre agence ou via votre espace client.'),
('Y a-t-il des frais mensuels sur mon compte ?', 'Oui, des frais de tenue de compte peuvent s’appliquer selon le type de compte.'),
('Puis-je avoir plusieurs comptes ?', 'Oui, il est possible d’avoir plusieurs comptes selon vos besoins.'),
('Puis-je ouvrir un compte sans revenu régulier ?', 'Oui, certains types de comptes ne nécessitent pas de revenu fixe.'),
('Comment modifier mes informations personnelles ?', 'Vous pouvez les modifier depuis votre espace client ou en agence.'),

('Comment obtenir une carte bancaire ?', 'Vous pouvez en faire la demande lors de l’ouverture de votre compte ou plus tard depuis votre espace client.'),
('En combien de temps je reçois ma carte ?', 'En général, vous la recevez sous 7 à 10 jours ouvrables.'),
('Que faire en cas de carte perdue ou volée ?', 'Bloquez immédiatement votre carte depuis l’application ou contactez le service client.'),
('Comment changer le code PIN de ma carte ?', 'Vous pouvez le modifier à un guichet automatique ou depuis votre espace client.'),
('Ma carte est expirée, que faire ?', 'Une nouvelle carte est automatiquement envoyée avant la date d’expiration.'),
('Puis-je utiliser ma carte à l’étranger ?', 'Oui, mais vérifiez que votre carte est activée pour les paiements internationaux.'),
('Quels sont les frais à l’étranger ?', 'Des frais de conversion et de retrait peuvent s’appliquer selon la zone géographique.'),
('Comment activer ma carte bancaire ?', 'Vous pouvez l’activer en effectuant un retrait ou un paiement avec votre code PIN.'),
('Comment augmenter le plafond de ma carte ?', 'Vous pouvez faire une demande d’augmentation temporaire ou permanente via votre espace client.'),
('Que faire si ma carte est bloquée ?', 'Contactez le service client pour la réinitialiser ou demandez une nouvelle carte.'),

('Comment effectuer un virement bancaire ?', 'Connectez-vous à votre espace client et sélectionnez “Effectuer un virement”.'),
('Y a-t-il des frais pour les virements ?', 'Les virements internes sont gratuits, mais les virements internationaux peuvent être payants.'),
('Combien de temps prend un virement ?', 'Un virement national prend entre 24 et 48 heures, un virement international peut prendre jusqu’à 5 jours ouvrables.'),
('Puis-je programmer un virement automatique ?', 'Oui, vous pouvez planifier des virements récurrents depuis votre espace client.'),
('Comment annuler un virement ?', 'Vous pouvez l’annuler avant son exécution, dans la section “Historique des virements”.'),
('Comment recevoir un paiement international ?', 'Fournissez à l’expéditeur votre IBAN et le code SWIFT/BIC de la banque.'),
('Qu’est-ce que l’IBAN ?', 'L’IBAN est un identifiant international de compte bancaire utilisé pour les transferts.'),
('Où trouver mon IBAN ?', 'Sur votre relevé bancaire ou dans votre espace client.'),
('Puis-je effectuer un virement sans IBAN ?', 'Non, l’IBAN est obligatoire pour identifier le compte bénéficiaire.'),
('Comment vérifier si un virement est bien arrivé ?', 'Vous pouvez consulter l’historique des transactions dans votre espace client.'),

('Comment faire une demande de prêt ?', 'Vous pouvez soumettre une demande en ligne ou en agence.'),
('Quels types de prêts proposez-vous ?', 'Prêts personnels, prêts immobiliers, prêts auto et crédits à la consommation.'),
('Combien de temps faut-il pour obtenir un prêt ?', 'En général, la réponse est donnée sous 48 à 72 heures après étude du dossier.'),
('Quelles sont les conditions pour un prêt personnel ?', 'Avoir un revenu stable et une bonne capacité de remboursement.'),
('Puis-je rembourser mon prêt par anticipation ?', 'Oui, c’est possible. Des frais peuvent s’appliquer selon le contrat.'),
('Comment connaître le taux d’intérêt actuel ?', 'Consultez notre site web ou contactez un conseiller.'),
('Puis-je regrouper plusieurs prêts ?', 'Oui, nous proposons des solutions de regroupement de crédits.'),
('Comment suivre mes remboursements ?', 'Consultez le tableau d’amortissement disponible dans votre espace client.'),
('Puis-je demander un prêt sans compte chez vous ?', 'Non, il faut d’abord ouvrir un compte bancaire.'),
('Quels documents sont nécessaires pour un prêt ?', 'Pièce d’identité, justificatif de revenus, et justificatif de domicile.'),

('Comment sécuriser mon compte bancaire ?', 'Ne partagez jamais vos identifiants et activez la double authentification.'),
('Que faire en cas de suspicion de fraude ?', 'Contactez immédiatement notre service antifraude.'),
('Qu’est-ce que la double authentification ?', 'C’est une mesure de sécurité supplémentaire qui vérifie votre identité lors des connexions.'),
('Comment changer mon mot de passe ?', 'Connectez-vous et allez dans la section “Sécurité du compte”.'),
('Que faire si j’ai oublié mon mot de passe ?', 'Utilisez la fonction “Mot de passe oublié” sur la page de connexion.'),
('Est-ce que mes informations sont protégées ?', 'Oui, toutes vos données sont chiffrées et sécurisées.'),
('Que faire si je reçois un mail suspect ?', 'Ne cliquez sur aucun lien et signalez-le à notre service de sécurité.'),
('Puis-je accéder à mon compte depuis plusieurs appareils ?', 'Oui, mais nous vous recommandons d’utiliser uniquement des appareils sécurisés.'),
('Comment contacter le service client ?', 'Par téléphone, par mail ou via le chat en ligne disponible sur notre site.'),
('Quelles sont vos heures d’ouverture ?', 'Nos agences sont ouvertes du lundi au vendredi, de 8h à 17h.');

INSERT INTO faq (question_faq, reponse_faq) VALUES
('Merci, merci, Thank you .ravi, plaisir' , 'Je vous en prie, plaisir partager');
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Quelle est l''heure d''ouverture?' , 'Nous ouvrons a partir de 8h et travaillons du lundi au samedi')

--Informations générales
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Quels services propose votre banque ?', 'Nous offrons des services de gestion de compte, prêts, cartes bancaires, transactions internationales et assistance client.'),
('Où se trouve votre agence la plus proche ?', 'Vous pouvez localiser nos agences via notre site web ou l''application mobile.'),
('Puis-je avoir un relevé bancaire mensuel ?', 'Oui, vos relevés sont disponibles en téléchargement dans votre espace client.'),
('Comment recevoir mes relevés bancaires par email ?', 'Activez l''option “Relevé électronique” dans votre espace client.'),
('Comment contacter un conseiller ?', 'Vous pouvez contacter un conseiller par téléphone, email ou via notre chat en ligne.');


--Cartes bancaires (niveau avancé)
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Pourquoi ma carte ne fonctionne-t-elle pas en ligne ?', 'Vérifiez que les paiements en ligne sont activés dans votre espace client.'),
('Que faire si mon paiement est refusé ?', 'Assurez-vous que votre solde est suffisant et que votre carte n''est pas bloquée.'),
('Comment activer le sans-contact ?', 'Le sans-contact s''active automatiquement après votre premier paiement avec code PIN.'),
('Quelle est la limite du paiement sans contact ?', 'La limite dépend du type de carte, généralement entre 10 000 et 25 000 FCFA.'),
('Comment désactiver le sans-contact ?', 'Vous pouvez le désactiver dans les paramètres de votre carte depuis l''application.');

--Comptes & Profil utilisateur
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Pourquoi mon compte est-il bloqué ?', 'Votre compte peut être bloqué pour suspicion de fraude, documents expirés ou activité inhabituelle.'),
('Comment débloquer mon compte ?', 'Contactez notre service client pour vérification de votre identité.'),
('Mon nom a changé, comment mettre à jour mon profil ?', 'Rendez-vous en agence avec votre document justificatif.'),
('Comment ajouter un bénéficiaire ?', 'Ajoutez un bénéficiaire depuis la section “Virements” dans votre espace client.'),
('Puis-je changer mon adresse email ?', 'Oui, vous pouvez la modifier dans la rubrique “Informations personnelles”.');

--Virements & transactions
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Pourquoi mon virement a été annulé ?', 'Il peut être annulé pour solde insuffisant ou bénéficiaire invalide.'),
('Puis-je envoyer de l''argent à une autre banque ?', 'Oui, via les virements interbancaires.'),
('Comment suivre un virement envoyé ?', 'Consultez votre historique des transactions.'),
('Puis-je faire un retrait sans carte ?', 'Oui, grâce au service de retrait sans carte via l''application.'),
('Puis-je modifier un virement programmé ?', 'Oui, tant qu''il n''a pas encore été exécuté.');

--Sécurité & Confidentialité
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment éviter les arnaques bancaires ?', 'Ne partagez jamais vos identifiants et vérifiez l''adresse des emails reçus.'),
('Pourquoi dois-je fournir mes documents ?', 'La vérification d''identité est exigée par les régulations financières.'),
('Que faire en cas de tentative de phishing ?', 'Ne cliquez sur aucun lien et signalez immédiatement le message.'),
('Comment protéger mon compte ?', 'Activez la double authentification et changez régulièrement votre mot de passe.'),
('Pourquoi ma connexion est-elle bloquée ?', 'Après plusieurs tentatives erronées, votre compte se bloque automatiquement pour sécurité.');

--Prêts & Crédit
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment connaître ma capacité d''emprunt ?', 'Vous pouvez utiliser notre simulateur en ligne ou contacter un conseiller.'),
('Comment suivre ma demande de prêt ?', 'Elle est visible dans votre espace client, rubrique “Mes demandes”.'),
('Puis-je renégocier mon crédit ?', 'Oui, contactez un conseiller pour étudier votre dossier.'),
('Qu''est-ce que le taux fixe ?', 'Un taux qui reste inchangé pendant toute la durée du prêt.'),
('Puis-je reporter une mensualité ?', 'Oui, sous certaines conditions prévues dans votre contrat.');

--Paiements & Débits
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Pourquoi ai-je un prélèvement inconnu ?', 'Vérifiez vos abonnements et paiements automatiques.'),
('Comment contester un prélèvement ?', 'Vous pouvez le contester via votre espace client ou en agence.'),
('Comment arrêter un abonnement ?', 'Supprimez l''autorisation de prélèvement dans votre espace client.'),
('Comment obtenir un remboursement ?', 'Le remboursement dépend du marchand, contactez-le directement.'),
('Pourquoi un paiement apparaît deux fois ?', 'Il peut s''agir d''une autorisation temporaire, elle disparaîtra automatiquement.');


--Application mobile & numérique
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Pourquoi je n''arrive pas à me connecter à l''application ?', 'Vérifiez votre connexion internet et vos identifiants.'),
('Comment activer les notifications ?', 'Activez-les depuis les paramètres de l''application.'),
('Comment changer la langue de l''application ?', 'Rendez-vous dans les paramètres généraux de l''application.'),
('Pourquoi le solde n''est pas mis à jour ?', 'Le solde peut prendre quelques minutes à se synchroniser.'),
('Comment activer l''authentification biométrique ?', 'Disponible dans la rubrique “Sécurité” de l''application.');


--Divers & Cas spéciaux
INSERT INTO faq (question_faq, reponse_faq) VALUES
('Le chatbot peut-il effectuer des transactions ?', 'Oui, pour certaines opérations sécurisées, mais une confirmation est requise.'),
('Comment changer la devise de mon compte ?', 'Cela nécessite l''ouverture d''un compte multi-devises en agence.'),
('Puis-je ouvrir un compte pour mon enfant ?', 'Oui, nous proposons des comptes jeunes.'),
('Puis-je créer plusieurs comptes épargne ?', 'Oui, selon vos besoins financiers.'),
('Que faire si une erreur s''affiche ?', 'Redémarrez votre session et réessayez ou contactez le support.');







-- ============================================
-- FAQ Banque – Version améliorée avec emojis
-- ============================================

INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment ouvrir un compte bancaire ?', '📝 Ouvrir un compte est facile ! Vous pouvez le faire en agence ou en ligne avec votre pièce d’identité, justificatif de domicile et une photo récente. 🚀'),
('Quels sont les types de comptes disponibles ?', '💳 Nous proposons : comptes courants pour vos dépenses, comptes épargne pour faire fructifier votre argent et comptes professionnels pour votre activité.'),
('Quels documents sont nécessaires pour ouvrir un compte ?', '📄 Pièce d’identité, justificatif de domicile et photo récente 🖼️. Facile à préparer !'),
('Combien de temps faut-il pour activer un compte ?', '⏳ Activation rapide : 24 à 48 heures après vérification. Vous serez notifié ! ✅'),
('Comment consulter le solde de mon compte ?', '💰 Via l’application mobile 📱, le site web 🌐 ou un distributeur automatique 🏧.'),

('Comment fermer mon compte bancaire ?', '📪 Envoyez une demande écrite en agence ou depuis votre espace client. N’oubliez pas de transférer vos fonds ! 💸'),
('Y a-t-il des frais mensuels sur mon compte ?', '💵 Certains comptes ont des frais. Consultez votre contrat ou espace client pour les détails.'),
('Puis-je avoir plusieurs comptes ?', '✅ Oui, vous pouvez ouvrir plusieurs comptes selon vos besoins personnels ou professionnels.'),
('Puis-je ouvrir un compte sans revenu régulier ?', '💡 Certains comptes ne nécessitent pas de revenu fixe. Contactez le support pour en savoir plus !'),
('Comment modifier mes informations personnelles ?', '✏️ Mettez à jour vos informations depuis votre espace client ou en agence avec vos justificatifs.') ,

('Comment obtenir une carte bancaire ?', '💳 Demandez-la à l’ouverture du compte ou plus tard depuis votre espace client. Sécurisé et rapide ! 🔒'),
('En combien de temps je reçois ma carte ?', '📦 Livraison sous 7 à 10 jours ouvrables. Patience… elle vaut le coup ! 😄'),
('Que faire en cas de carte perdue ou volée ?', '🚨 Bloquez-la immédiatement via l’application ou contactez le service client pour éviter toute fraude.'),
('Comment changer le code PIN de ma carte ?', '🔑 Changez votre PIN à un guichet automatique ou depuis votre espace client.'),
('Ma carte est expirée, que faire ?', '🆕 Une nouvelle carte est envoyée automatiquement avant l’expiration. Vérifiez votre boîte aux lettres ou espace client.'),

('Puis-je utiliser ma carte à l’étranger ?', '🌍 Oui, activez-la pour paiements internationaux et vérifiez vos plafonds.'),
('Quels sont les frais à l’étranger ?', '💸 Des frais peuvent s’appliquer selon la zone. Consultez notre grille tarifaire.'),
('Comment activer ma carte bancaire ?', '✅ Activez-la avec un retrait ou paiement PIN. Prêt à l’emploi !'),
('Comment augmenter le plafond de ma carte ?', '📈 Demandez une augmentation temporaire ou permanente depuis votre espace client.'),
('Que faire si ma carte est bloquée ?', '🛑 Contactez le service client pour la débloquer ou demander une nouvelle carte.'),

('Comment effectuer un virement bancaire ?', '💸 Connectez-vous à votre espace client, sélectionnez “Effectuer un virement” et suivez les étapes. 🚀'),
('Y a-t-il des frais pour les virements ?', '✅ Virements internes gratuits, internationaux peuvent avoir des frais.'),
('Combien de temps prend un virement ?', '⏱️ National : 24-48h, international : jusqu’à 5 jours ouvrables.'),
('Puis-je programmer un virement automatique ?', '📅 Oui, planifiez vos virements récurrents depuis votre espace client. Plus d’oublis !'),
('Comment annuler un virement ?', '❌ Tant qu’il n’est pas exécuté, annulez-le depuis l’historique.'),
('Comment recevoir un paiement international ?', '🌐 Fournissez votre IBAN et code SWIFT/BIC à l’expéditeur.'),
('Qu’est-ce que l’IBAN ?', 'ℹ️ Identifiant international unique pour votre compte, indispensable pour les virements.'),
('Où trouver mon IBAN ?', '📃 Sur votre relevé, dans l’application ou espace client.'),
('Puis-je effectuer un virement sans IBAN ?', '❌ Non, l’IBAN est obligatoire pour identifier le bénéficiaire.'),
('Comment vérifier si un virement est bien arrivé ?', '✔️ Consultez l’historique de transactions dans votre espace client.'),

('Comment faire une demande de prêt ?', '🏦 Demandez en ligne ou en agence. Un conseiller vous guidera.'),
('Quels types de prêts proposez-vous ?', '💰 Prêts personnels, immobiliers, auto et crédits à la consommation.'),
('Combien de temps faut-il pour obtenir un prêt ?', '⏳ Réponse en 48-72h après étude du dossier.'),
('Quelles sont les conditions pour un prêt personnel ?', '📋 Revenu stable et capacité de remboursement. Facile à vérifier.'),
('Puis-je rembourser mon prêt par anticipation ?', '💡 Oui, possible. Des frais peuvent s’appliquer selon le contrat.'),
('Comment connaître le taux d’intérêt actuel ?', '📊 Consultez le site web ou contactez un conseiller pour le taux exact.'),
('Puis-je regrouper plusieurs prêts ?', '🔗 Oui, solutions de regroupement disponibles pour simplifier vos remboursements.'),
('Comment suivre mes remboursements ?', '📅 Tableau d’amortissement disponible dans l’espace client.'),
('Puis-je demander un prêt sans compte chez vous ?', '❌ Non, un compte bancaire est requis.'),
('Quels documents sont nécessaires pour un prêt ?', '📝 Pièce d’identité, justificatif de revenus et domicile.') ,

('Comment sécuriser mon compte bancaire ?', '🔒 Activez la double authentification, changez vos mots de passe régulièrement et ne partagez jamais vos identifiants.'),
('Que faire en cas de suspicion de fraude ?', '🚨 Contactez immédiatement notre service antifraude.'),
('Qu’est-ce que la double authentification ?', '✅ Couche de sécurité supplémentaire pour protéger vos connexions et transactions.'),
('Comment changer mon mot de passe ?', '🔑 Allez dans “Sécurité du compte” pour le modifier facilement.'),
('Que faire si j’ai oublié mon mot de passe ?', '🔄 Utilisez “Mot de passe oublié” pour le réinitialiser.'),
('Est-ce que mes informations sont protégées ?', '🛡️ Oui, toutes vos données sont chiffrées et sécurisées.'),
('Que faire si je reçois un mail suspect ?', '⚠️ Ne cliquez sur aucun lien et signalez-le au service sécurité.'),
('Puis-je accéder à mon compte depuis plusieurs appareils ?', '📱💻 Oui, mais utilisez uniquement des appareils sécurisés.'),
('Comment contacter le service client ?', '📞 Par téléphone, mail ou chat en ligne, nous sommes là pour vous aider !'),
('Quelles sont vos heures d’ouverture ?', '⏰ Du lundi au vendredi, 8h-17h. Support en ligne disponible le week-end !');


--Supplementaire

INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment contacter un conseiller ?', '📞 Depuis l’application ou en appelant le service client. Vous pouvez aussi demander un rendez-vous en agence 🏦.'),
('Puis-je discuter avec un agent humain ?', '👨‍💼 Bien sûr ! Demandez “Contacter un agent” et nous vous redirigeons vers un conseiller disponible.'),
('Comment signaler une fraude ?', '🚨 Connectez-vous à votre espace client et signalez immédiatement toute opération suspecte ou appelez le service antifraude.'),
('J’ai reçu un SMS ou email suspect de la banque, que faire ?', '⚠️ Ne cliquez sur aucun lien et transférez le message à notre cellule de sécurité. Nous vérifions rapidement !🔒'),
('Comment protéger ma carte sur Internet ?', '🛡️ Activez 3D Secure et ne partagez jamais vos informations bancaires sur des sites non sécurisés (🔒 dans la barre).'),
('Comment savoir si un site est sécurisé ?', '🔍 Le site doit afficher un cadenas 🔒 et commencer par https://. Sinon, danger ⚠️');


INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment installer l’application mobile ?', '📲 Dans Play Store ou App Store. Recherchez notre banque et cliquez sur Installer ✔️'),
('Je n’arrive pas à me connecter à mon espace client, que faire ?', '🔄 Vérifiez vos identifiants puis réinitialisez votre mot de passe si nécessaire.'),
('Puis-je recevoir des alertes de transactions ?', '🔔 Oui ! Activez les notifications dans l’application mobile.'),
('Est-il possible de désactiver temporairement ma carte ?', '🛑 Oui, vous pouvez verrouiller/déverrouiller votre carte en un clic depuis l’application. Hyper pratique ! 🔐');


INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment commander un chéquier ?', '📬 Commandez en ligne ou en agence. Livraison à domicile ou retrait en agence ✔️'),
('Comment obtenir un relevé de compte ?', '📄 Téléchargez-le depuis votre espace client ou demandez un envoi mensuel.'),
('Y a-t-il des frais pour le relevé papier ?', '📦 Oui, des frais peuvent s’appliquer selon votre offre bancaire.');


INSERT INTO faq (question_faq, reponse_faq) VALUES
('Pourquoi mon paiement a été refusé ?', '⛔ Vérifiez votre solde, plafond de carte ou la méthode d’authentification.'),
('Pourquoi mon compte est-il bloqué ?', '🚫 Peut être dû à une sécurité renforcée ou incident de paiement. Contactez un conseiller pour le débloquer.'),
('Mon retrait a échoué mais l’argent a été débité, que faire ?', '⚠️ Pas d’inquiétude ! Le montant est généralement recrédité sous 24-48h. Sinon contactez-nous.');



INSERT INTO faq (question_faq, reponse_faq) VALUES
('Comment obtenir un découvert autorisé ?', '📊 Disponible selon vos revenus et historique bancaire. Demandez via application ou en agence.'),
('Quels sont les frais de découvert ?', '💸 Les intérêts varient selon votre situation. Consultez votre contrat ou service client.');


INSERT INTO faq (question_faq, reponse_faq) VALUES
('Puis-je ouvrir un compte en étant étudiant ?', '🎓 Oui bien sûr ! Des offres avantageuses sont disponibles pour les jeunes.'),
('Quel âge pour ouvrir un compte ?', '👶 Avec un tuteur dès 12 ans. Autonome à partir de 18 ans.');


INSERT INTO faq (question_faq, reponse_faq) VALUES
('Proposez-vous des assurances ?', '🛡 Oui : moyens de paiement, habitation, auto, etc. Demandez selon vos besoins !');



INSERT INTO faq (question_faq, reponse_faq) VALUES
('Bonjour', '👋 Bonjour et bienvenue. je suis Yakfis-Bot, Votre assistant bancaire sympa😊! Comment puis-je vous aider aujourd’hui ? 😊'),
('Salut', 'Hey 👋 Comment puis-je vous assister ?'),
('Bonsoir', '✨ Bonsoir ! Besoin d’aide sur un service bancaire ?'),
('Hello', 'Hello 👋 I can help you with banking services if you want! 😊'),

('Qui es-tu ?', '🤖 Je suis votre assistant bancaire virtuel, toujours là pour vous aider 💪'),
('Qui t’a créé ?', '👨‍💻 Je suis créé par le grand informaticien,le pere vénéré Yakfis-FBi 💪 ! 😊'),
('Es-tu humain ?', '😄 Pas encore ! Je suis un chatbot, mais je fais de mon mieux pour être sympa 🤗'),
('Tu fais quoi ?', '🧠 Je réponds à vos questions et vous aide dans vos démarches bancaires 📌'),

('Merci', '🙏 Avec plaisir ! N’hésitez pas si vous avez d’autres questions 😊'),
('Merci beaucoup', '🥰 Je suis là pour ça ! D’autres besoins ?'),
('Ok merci', '👍 Parfait ! N’hésitez pas si besoin 😉'),

('Au revoir', '👋 À bientôt ! Prenez soin de vous 🏦'),
('Bye', 'Bye bye 👋 Revenez quand vous voulez !'),
('Bonne journée', '🌞 Merci ! À vous aussi une excellente journée !'),
('Bonne soirée', '🌙 Merci ! Passez une belle soirée ✨'),

('Raconte une blague', '😄 Pourquoi les banquiers ne jouent-ils jamais à cache-cache ? Parce que l’argent se retrouve toujours 🏦💸😂'),
('Tu es drôle', '😎 J’essaie toujours d’ajouter un peu de fun dans vos finances !'),
('Tu es nul', '😢 Oh… je vais m’améliorer. Dites-moi comment je peux mieux vous aider ❤️'),

('Je t’aime', '🥹 Aww merci ! Mais je préfère garder une relation… bancaire 💳❤️'),
('Tu dors ?', '😴 Jamais ! Je suis disponible 24h/24 pour vous aider 🚀');




TRUNCATE TABLE faq RESTART IDENTITY;

--pg_trgm = trigrammes
--👉 Cela permet de faire des recherches approximate matching = tolère les fautes d’orthographe, mots partiels

CREATE EXTENSION IF NOT EXISTS pg_trgm;

Crée un index pour accélérer les recherches
CREATE INDEX faq_question_trgm_idx
ON faq
USING gin (question_faq gin_trgm_ops);


SELECT question_faq, reponse_faq
FROM faq
WHERE question_faq % 'ouvrir un compte'
ORDER BY similarity(question_faq, 'ouvrir un compte') DESC
LIMIT 5;

