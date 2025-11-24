import psycopg2

def get_connection():
    return psycopg2.connect(
        host="localhost",
        port="5433",
        dbname="chatbot_bancaire_db",
        user="postgres",
        password="admin123"
    )



# ======================================
# Fonctions pour comptes et transactions
# ======================================

def get_comptes_user(user_id):
    """Récupère tous les comptes d'un utilisateur"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id_compte, numero_compte, type_compte, solde_compte, statut_compte
        FROM compte
        WHERE id_user = %s
    """, (user_id,))
    comptes = cur.fetchall()
    cur.close()
    conn.close()
    return comptes


def get_transactions_compte(id_compte, limit=10):
    """Récupère les dernières transactions d'un compte"""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT type_transaction, montant_transaction, date_transaction, statut_transaction
        FROM trans_client
        WHERE id_compte = %s
        ORDER BY date_transaction DESC
        LIMIT %s
    """, (id_compte, limit))
    transactions = cur.fetchall()
    cur.close()
    conn.close()
    return 



# =============================
# Récupérer les comptes du user
# =============================
def get_comptes_user(id_user):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id_compte, type_compte, numero_compte, solde_compte
        FROM compte
        WHERE id_user = %s
    """, (id_user,))
    comptes = cur.fetchall()
    conn.close()
    return comptes

# =============================
# Récupérer transactions d’un compte
# =============================
def get_transactions_compte(id_compte, limit=5):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT type_transaction, montant_transaction, date_transaction, statut_transaction
        FROM trans_client
        WHERE id_compte = %s
        ORDER BY date_transaction DESC
        LIMIT %s
    """, (id_compte, limit))

    trans = cur.fetchall()
    conn.close()
    return trans

# =============================
# Récupérer cartes bancaires d’un user
# =============================

def get_cartes_user(id_user):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT c.id_carte, c.numero_carte, c.type_carte, c.date_expiration, c.statut_carte
        FROM carte c
        JOIN compte co ON c.id_compte = co.id_compte
        WHERE co.id_user = %s
    """, (id_user,))
    cartes = cur.fetchall()
    conn.close()
    return cartes




# =============================
# Bloquer une carte
# =============================
def bloquer_carte(id_carte):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE carte
        SET statut_carte = 'bloquée'
        WHERE id_carte = %s
    """, (id_carte,))
    conn.commit()
    conn.close()

# =============================
# Remplacer une carte
# =============================
def remplacer_carte(id_carte):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE carte
        SET statut_carte = 'remplacée'
        WHERE id_carte = %s
    """, (id_carte,))
    conn.commit()
    conn.close()




# =============================
# Effectuer une transaction
# =============================


#Verifier si le compte existe
def get_compte_by_numero(numero_compte):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id_compte, solde_compte FROM compte
        WHERE numero_compte = %s
    """, (numero_compte,))
    compte = cur.fetchone()
    conn.close()
    return compte




def effectuer_transaction(id_compte_source, id_compte_dest, montant):
    conn = get_connection()
    cur = conn.cursor()
    try:
        # Récupérer solde du compte source
        cur.execute("SELECT solde_compte FROM compte WHERE id_compte=%s", (id_compte_source,))
        result = cur.fetchone()
        if not result:
            # Compte source inexistant -> transaction refusée
            cur.execute("""
                INSERT INTO trans_client(id_compte, id_compte_dest, montant_transaction, type_transaction, statut_transaction)
                VALUES (%s, %s, %s, 'envoi', 'refusée')
                RETURNING id_transaction
            """, (id_compte_source, id_compte_dest, montant))
            id_trans = cur.fetchone()[0]

            # Enregistrer suspicion
            cur.execute("""
                INSERT INTO suspicion(id_transaction, raison_suspicion, niveau_risque)
                VALUES (%s, %s, %s)
            """, (id_trans, "Compte source inexistant", "élevé"))

            conn.commit()
            return False, "Le compte source n'existe pas."

        solde_source = result[0]

        # Vérifier limite maximale par transaction
        if montant > 1000000:
            # Transaction refusée -> suspicion
            cur.execute("""
                INSERT INTO trans_client(id_compte, id_compte_dest, montant_transaction, type_transaction, statut_transaction)
                VALUES (%s, %s, %s, 'envoi', 'refusée')
                RETURNING id_transaction
            """, (id_compte_source, id_compte_dest, montant))
            id_trans = cur.fetchone()[0]

            cur.execute("""
                INSERT INTO suspicion(id_transaction, raison_suspicion, niveau_risque)
                VALUES (%s, %s, %s)
            """, (id_trans, "Montant supérieur à 1 million", "élevé"))

            conn.commit()
            return False, "❌Transaction annulee,Le montant maximum autorisé par transaction est 1 000 000 FCFA."

        # Vérifier solde insuffisant
        if solde_source < montant:
            return False, f"❌Solde insuffisant ({solde_source} FCFA). Veuillez saisir un montant inférieur ou égal à votre solde."

        # Débiter compte source
        cur.execute("""
            UPDATE compte
            SET solde_compte = solde_compte - %s
            WHERE id_compte = %s
        """, (montant, id_compte_source))

        # Créditer compte destinataire
        cur.execute("""
            UPDATE compte
            SET solde_compte = solde_compte + %s
            WHERE id_compte = %s
        """, (montant, id_compte_dest))

        # Enregistrer transaction réussie
        cur.execute("""
            INSERT INTO trans_client(id_compte, id_compte_dest, montant_transaction, type_transaction, statut_transaction)
            VALUES (%s, %s, %s, 'envoi', 'réussie')
        """, (id_compte_source, id_compte_dest, montant))

        conn.commit()
        return True, f"Transaction réussie ! Vous avez envoyé {montant} FCFA au compte destinataire."

    except Exception as e:
        conn.rollback()
        print("Erreur transaction :", e)
        return False, "Une erreur est survenue lors de la transaction."
    finally:
        conn.close()











'''
def effectuer_transaction(id_compte_source, id_compte_dest, montant):
    conn = get_connection()
    cur = conn.cursor()
    try:
        # Récupérer solde du compte source
        cur.execute("SELECT solde_compte FROM compte WHERE id_compte=%s", (id_compte_source,))
        result = cur.fetchone()
        if not result:
            # Compte source inexistant -> transaction refusée
            cur.execute("""
                INSERT INTO trans_client(id_compte, id_compte_dest, montant_transaction, type_transaction, statut_transaction)
                VALUES (%s, %s, %s, 'envoi', 'refusée')
                RETURNING id_transaction
            """, (id_compte_source, id_compte_dest, montant))
            id_trans = cur.fetchone()[0]

            # Enregistrer suspicion
            cur.execute("""
                INSERT INTO suspicion(id_transaction, raison_suspicion, niveau_risque)
                VALUES (%s, %s, %s)
            """, (id_trans, "Compte source inexistant", "élevé"))

            conn.commit()
            return False

        solde_source = result[0]


        



        if solde_source < montant:
            # Transaction refusée -> solde insuffisant
            cur.execute("""
                INSERT INTO trans_client(id_compte, id_compte_dest, montant_transaction, type_transaction, statut_transaction)
                VALUES (%s, %s, %s, 'envoi', 'refusée')
                RETURNING id_transaction
            """, (id_compte_source, id_compte_dest, montant))
            id_trans = cur.fetchone()[0]

            # Enregistrer suspicion
            cur.execute("""
                INSERT INTO suspicion(id_transaction, raison_suspicion, niveau_risque)
                VALUES (%s, %s, %s)
            """, (id_trans, "Montant supérieur au solde", "élevé"))

            conn.commit()
            return False

        # Débiter compte source
        cur.execute("""
            UPDATE compte
            SET solde_compte = solde_compte - %s
            WHERE id_compte = %s
        """, (montant, id_compte_source))

        # Créditer compte destinataire
        cur.execute("""
            UPDATE compte
            SET solde_compte = solde_compte + %s
            WHERE id_compte = %s
        """, (montant, id_compte_dest))

        # Enregistrer transaction réussie
        cur.execute("""
            INSERT INTO trans_client(id_compte, id_compte_dest, montant_transaction, type_transaction, statut_transaction)
            VALUES (%s, %s, %s, 'envoi', 'réussie')
        """, (id_compte_source, id_compte_dest, montant))

        conn.commit()
        return True

    except Exception as e:
        conn.rollback()
        print("Erreur transaction :", e)
        return False
    finally:
        conn.close()


'''
    

