import spacy
from flask import session
from database import (
    get_connection,
    get_comptes_user,
    get_transactions_compte,
    get_cartes_user,
    bloquer_carte,
    remplacer_carte,
    get_compte_by_numero,
    effectuer_transaction
)
from psycopg2.extras import RealDictCursor

# Chargement du modèle SpaCy (une seule fois)
nlp_model = None
def get_nlp_model():
    global nlp_model
    if nlp_model is None:
        print("Chargement modèle SpaCy...")
        nlp_model = spacy.load("fr_core_news_lg")
        print("Modèle chargé !")
    return nlp_model

def masquer_numero(numero):
    return "**** **** **** " + numero[-4:]

def choisir_carte(cartes):
    txt = "Vous avez plusieurs cartes. Laquelle voulez-vous utiliser ?\n"
    for i, c in enumerate(cartes, start=1):
        txt += f"{i}. Carte {masquer_numero(c[1])} ({c[2]}), expire le {c[3]}, statut : {c[4]}\n"
    return txt

# ================================
# Gestion cartes
# ================================
def gestion_cartes(question, user_id):
    question_lower = question.lower().strip()
    cartes = get_cartes_user(user_id)
    if not cartes:
        return "Vous n'avez aucune carte bancaire enregistrée."

    etat_keywords = ["etat", "statut", "infos", "informations", "consulter le statut", "consulter statut"]
    blocage_keywords = ["bloquer", "verrouiller"]
    remplacement_keywords = ["remplacer", "renouveler"]

    if any(k in question_lower for k in etat_keywords):
        txt = "Voici vos cartes :\n"
        for i, c in enumerate(cartes, start=1):
            txt += f"\n{i}. Carte {masquer_numero(c[1])} ({c[2]}), expirant le {c[3]}, statut : {c[4]}\n"
        return txt

    if question_lower.isdigit():
        idx = int(question_lower)
        if 1 <= idx <= len(cartes):
            carte = cartes[idx - 1]
            masked = masquer_numero(carte[1])
            session["carte_id"] = carte[0]
            session["carte_num"] = masked
            action = session.get("action")
            if action == "bloquer":
                return f"Confirmez-vous le blocage de la carte {masked} ? Répondez OUI."
            if action == "remplacer":
                return f"Confirmez-vous le remplacement de la carte {masked} ? Répondez OUI."

    if question_lower == "oui":
        action = session.get("action")
        carte_id = session.get("carte_id")
        carte_num = session.get("carte_num")
        if not action:
            return "Aucune opération en attente. Que souhaitez-vous faire ?"
        if action == "bloquer":
            bloquer_carte(carte_id)
            session["action"] = None
            return f"Votre carte {carte_num} a été bloquée avec succès."
        if action == "remplacer":
            remplacer_carte(carte_id)
            session["action"] = None
            return f"Votre carte {carte_num} a été remplacée avec succès."

    if any(k in question_lower for k in blocage_keywords):
        session["action"] = "bloquer"
        if len(cartes) > 1:
            return choisir_carte(cartes)
        carte = cartes[0]
        masked = masquer_numero(carte[1])
        session["carte_id"] = carte[0]
        session["carte_num"] = masked
        return f"Voulez-vous vraiment bloquer la carte {masked} ? Répondez OUI."

    if any(k in question_lower for k in remplacement_keywords):
        session["action"] = "remplacer"
        if len(cartes) > 1:
            return choisir_carte(cartes)
        carte = cartes[0]
        masked = masquer_numero(carte[1])
        session["carte_id"] = carte[0]
        session["carte_num"] = masked
        return f"Voulez-vous vraiment remplacer la carte {masked} ? Répondez OUI."

    return "Que souhaitez-vous faire avec votre carte ?\n- Consulter le statut\n- Bloquer\n- Remplacer"

# ================================
# Gestion transactions
# ================================
def gestion_transactions(question, user_id, current_conv):
    step_key = f"step_conv_{current_conv}"
    step = session.get(step_key, None)
    question_lower = question.lower().strip()
    trigger_keywords = ["envoyer", "transférer", "virement", "faire une transaction","effectuer une transaction"]

    if step is None and any(k in question_lower for k in trigger_keywords):
        session[step_key] = "dest"
        return "Très bien 😊. Quel est le numéro du compte destinataire ?"

    if step == "dest":
        numero_saisi = question.strip().upper().replace(" ", "")
        compte_dest = get_compte_by_numero(numero_saisi)
        if not compte_dest:
            return "❌ Ce numéro de compte n'existe pas. Réessayez ou tapez une autre commande."
        session["compte_dest"] = compte_dest
        session[step_key] = "montant"
        return f"Parfait 👍. Vous allez envoyer de l'argent au compte {numero_saisi}. Quel montant souhaitez-vous envoyer ?"

    if step == "montant":
        question_clean = question.strip().lower()
        if question_clean in ["annuler", "stop", "retour"]:
            session[step_key] = None
            session["compt_dest"] = None
            return " ❌Transaction annulée."

        try:
            montant = float(question.replace(',', '.'))
        except ValueError:
            session[step_key] = None
            session["compte_dest"] = None
            return "❌ Veuillez saisir un montant valide."

        if montant <= 0:
            return "❌ Le montant doit être positif."

        comptes = get_comptes_user(user_id)
        if not comptes:
            session[step_key] = None
            session["compte_dest"] = None
            return "❌ Vous n'avez aucun compte pour effectuer cette transaction."

        compte_source = comptes[0]
        id_compte_source = compte_source[0]
        id_compte_dest = session["compte_dest"][0]

        succes, message = effectuer_transaction(id_compte_source, id_compte_dest, montant)
        session[step_key]=None
        session["compte_dest"]=None
        if succes:
            return f"🎉 Transaction réussie !\n💸 Vous avez envoyé {montant} FCFA avec succès !\n{message}"

        else:
        
            return message

# =======================================
# Main chatbot logic avec NLP et pg_trgm
# =======================================
def trouver_reponse(question_user, user_id=None, current_conv=None):
    question_lower = question_user.lower().strip()

    # Gestion solde
    if user_id:
        if any(k in question_lower for k in ["solde", "consulter solde", "consulter argent", "consulter mon argent"]):
            comptes = get_comptes_user(user_id)
            if not comptes:
                return "Vous n'avez aucun compte enregistré."
            texte = "💰 *Vos soldes bancaires*\n\n"
            for c in comptes:
                solde = f"{c[3]:,}".replace(",", " ")
                texte += f"• **{c[2]}** (N° {c[1]}) : **{solde} FCFA**\n"
            return texte

        # Historique transactions
        if any(k in question_lower for k in ["historique", "mes transactions", "transactions"]):
            comptes = get_comptes_user(user_id)
            if not comptes:
                return "❌ Vous n'avez aucun compte."

            texte = "📄 *Historique des transactions*\n\n"
            for c in comptes:
                texte += f"💳 Compte **{c[2]}** (N° {c[1]})\n"
                trans = get_transactions_compte(c[0])

                if not trans:
                    texte += "   ➖ Aucune transaction récente\n\n"
                    continue

                for t in trans:
                    montant = f"{t[1]:,}".replace(",", " ")
                    date = t[2].strftime("%d/%m/%Y") if hasattr(t[2], "strftime") else t[2]
                    texte += f"   • {montant} FCFA — {t[3]} ({date})\n"

                texte += "\n"
            texte = texte.replace("\n", "<br>")

            return texte

    # Gestion cartes
    keywords_cartes_bancaires = [
    "bloquer", "verrouiller", "remplacer",
    "renouveler", "statut", "etat",
    "ma carte", "carte bancaire"
    ]

    if user_id and any(k in question_lower for k in keywords_cartes_bancaires):
      return gestion_cartes(question_lower, user_id)



    # Gestion transactions étape par étape
    if user_id and current_conv:
        rep = gestion_transactions(question_lower, user_id, current_conv)
        if rep:
            return rep

    # ============================
    # NLP + pg_trgm pour FAQ
    # ============================
    conn = get_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    question_lower = question_lower.strip()
    # Récupération avec pg_trgm
    cur.execute("""
        SELECT question_faq, reponse_faq
        FROM faq
        WHERE similarity(question_faq, %s) > 0.5
        ORDER BY similarity(question_faq, %s) DESC
        LIMIT 10
    """, (question_lower, question_lower))
    faqs = cur.fetchall()

    print(f"Nombre de FAQ récupérées : {len(faqs)}")
    print(f"Exemple de FAQ : {faqs[:3]}")

    cur.close()
    conn.close()

    if not faqs:
        return "Je suis désolé, je n'ai pas trouvé de réponse proche."

    # Calcul de similarité sémantique
    nlp = get_nlp_model()
    doc_user = nlp(question_lower)

    best_score = 0
    best_answer = None
    for item in faqs:
        doc_faq = nlp(item['question_faq'].lower())
        score = doc_user.similarity(doc_faq)
        if score > best_score:
            best_score = score
            best_answer = item['reponse_faq']

    return best_answer if best_score >= 0.6 else "Je suis désolé, je n'ai pas compris votre demande."





