#============================
#Importation des bibliotheque
#============================
from flask import Flask, render_template, request, redirect, url_for, flash, session
from nlp import trouver_reponse
from database import get_connection, get_transactions_for_dashboard, get_suspicions, set_suspicion_decision
import psycopg2
from functools import wraps




#Creaton de lapp
app = Flask(__name__)
#Cle secrete pour la gestion des session
app.secret_key = "74524cba05887d3720a5bc2fb828a3d86c58316cb492bc08891e3983796e8e80"


@app.template_filter('nl2br')
def nl2br(value):
    return value.replace("\n", "<br>")




# =========================
#  Page d'accueil
# =========================
@app.route("/")
def acceuil():
    return render_template("accueil.html")

# =========================
# Connexion utilisateur
# =========================

#Declaration d'une fonction flask qui repond a l'url /connexion
@app.route("/connexion", methods=["GET", "POST"])
def connexion():
    if request.method == "POST":       #Verifier si un formulaire a ete envoyer par le user(post=formulaire, get= juste un acces a une page)
        email = request.form["email"]   #Recuperer les valeur saisi par le user dans le formulaire
        mdp = request.form["mdp"]

        try: # Gestion des erreur et Connexion a la bd
            conn = get_connection()
            cur = conn.cursor()     #creer un curseur pour interragir avec la bd, ajouter ,supprimer,selionner des element dans une table de la bd
            #Selectionner des element de la table utilisateur
            cur.execute("""         
                SELECT id_user, nom_user, prenom_user, type_user
                FROM utilisateur
                WHERE email_user=%s AND mot_de_passe=%s
            """, (email, mdp))
            user = cur.fetchone()   #Initialiser une variable user sous fornme de tuple ()qui prend la ligne selectioner dans la bd(ex:user = (5, "Ali", "Mohamed"))
        except psycopg2.Error as e: # afficher un message derreur en cas derreur lier a la bd
            flash(f"Erreur base de données : {e}", "danger")
            user = None      #en cas derreur la variable user ne contient pas de donnees
        finally:    #Fermer la connexion a la bd apres lacces
            if conn:
                conn.close()

        if user: #verifie si user valide est trouver dans la bd
            # Stocker les infos dans la session
            session["user_id"] = user[0] #stocke lid du user a lindex 0 dans le tupe
            session["nom_user"] = user[1]  #index 1 etc..
            session["prenom_user"] = user[2]
            session["type_user"] = user[3].strip().lower()
            flash(f"Bienvenue {user[2]} 👋 !", "success")
            
            if user[3] == "conseiller":
                return redirect(url_for("dashboard"))
            else:
                return redirect(url_for("chatbot"))
        

        else:  #si les infos saisi sont incorrect
            flash("Erreur : email ou mot de passe incorrect.", "danger")
   
    return render_template("connexion.html") #si la methide est get ou si la connexion echoue on reaffiche la page de connexion au user a  nouveau

# =========================
#  Déconnexion
# =========================
@app.route("/deconnexion")
def deconnexion():
    session.clear() #Netoyer les infos de la session une fois le user deconnecter pour la securiter
    flash("Vous avez été déconnecté.", "info")
    return redirect(url_for("acceuil"))




# =========================
#  Chatbot principal
# =========================

@app.route("/chatbot", methods=["GET", "POST"])
def chatbot():
    if "user_id" not in session:
        flash("Veuillez vous connecter pour accéder au chatbot.", "warning")
        return redirect(url_for("connexion"))

    user_id = session["user_id"]
    prenom = session["prenom_user"]
     
    historique = []
    conversations = []
    current_conv = None
    rows = []
   

    try:
        conn = get_connection()
        cur = conn.cursor()

        # ---------------------------
        # 1️⃣ Créer une nouvelle conversation
        # ---------------------------
        if request.method == "POST" and "titre" in request.form:
            titre = request.form["titre"]
            cur.execute("""
                INSERT INTO conversation (id_user, titre)
                VALUES (%s, %s) RETURNING id_conversation
            """, (user_id, titre))
            current_conv = cur.fetchone()[0]
            conn.commit()
            flash(f"Conversation '{titre}' créée !", "success")
        else:
            current_conv = request.args.get("conv_id", type=int)

        # ---------------------------
        # 2️⃣ Récupérer toutes les conversations de l'utilisateur
        # ---------------------------
        cur.execute("""
            SELECT id_conversation, titre
            FROM conversation
            WHERE id_user=%s
            ORDER BY date_creation DESC
        """, (user_id,))
        conversations = cur.fetchall()
        
        current_conv = request.form.get("conv_id", type=int) or request.args.get("conv_id", type=int)

        # Si aucune conversation sélectionnée, prendre la dernière
        if not current_conv and conversations:
            current_conv = conversations[0][0]


        # ---------------------------
        # 3️⃣ Envoyer un message dans la conversation sélectionnée
        # ---------------------------
        if request.method == "POST" and "message" in request.form:
            question = request.form["message"]
            reponse = trouver_reponse(question, user_id=user_id, current_conv=current_conv)


             # Ajouter directement au historique pour l'affichage immédiat
            historique.append((question, None, "user"))
            historique.append((None, reponse, "bot"))

            cur.execute("""
                INSERT INTO interaction (id_user, question_user, reponse_chatbot, id_conversation)
                VALUES (%s, %s, %s, %s)
            """, (user_id, question, reponse, current_conv))
            conn.commit()

        #Charger toutes l'historique
        historique = []
        if current_conv:
            cur.execute("""
                  SELECT question_user, reponse_chatbot
                  FROM interaction
                  WHERE id_user=%s AND id_conversation=%s
                  ORDER BY date_interaction ASC
            """,(user_id, current_conv))
            rows = cur.fetchall()

        # -------------------------------------------------------------------
        # 4️⃣ Charger l'historique des messages pour la conversation courante
        # -------------------------------------------------------------------
        
        
        
            # Construire l'historique sous forme (msg_user, msg_bot, role)
        for question, reponse in rows:
                # Message de l'utilisateur
                historique.append((question, None, "user"))

                # Message du bot
                historique.append((None, reponse, "bot"))
        

    except psycopg2.Error as e:
        flash(f"Erreur base de données : {e}", "danger")

    finally:
        if conn:
            conn.close()

    return render_template(
        "chatbot.html",
        prenom=prenom,
        historique=historique,
        conversations=conversations,
        current_conv=current_conv
    )





#  protéger l'accès aux analystes (conseillers)
def login_required_analyste(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if "user_id" not in session:
            flash("Veuillez vous connecter.", "warning")
            return redirect(url_for("connexion"))
        # vérifier le type
        if session.get("type_user", "").lower() != "conseiller":
            flash("Accès réservé aux analystes.", "danger")
            return redirect(url_for("acceuil"))
        return f(*args, **kwargs)
    return decorated

#Route pour le dashbord
@app.route("/dashboard")
@login_required_analyste
def dashboard():
    try:
        transactions = get_transactions_for_dashboard(limit=500)
        suspicions = get_suspicions(limit=500)
    except Exception as e:
        flash(f"Erreur base de données : {e}", "danger")
        transactions = []
        suspicions = []

    return render_template("dashboard.html",
                           transactions=transactions,
                           suspicions=suspicions)

# action POST pour valider suspicion
@app.route("/suspicion/<int:id_suspicion>/valider", methods=["POST"])
@login_required_analyste
def valider_suspicion(id_suspicion):
    id_analyste = session.get("user_id")
    commentaire = request.form.get("commentaire", None)
    ok = set_suspicion_decision(id_suspicion, id_analyste, "validee", commentaire)
    if ok:
        flash("Suspicion validée et marquée comme 'validée'.", "success")
    else:
        flash("Erreur lors de la validation.", "danger")
    return redirect(url_for("dashboard"))

# action POST pour refuser suspicion
@app.route("/suspicion/<int:id_suspicion>/refuser", methods=["POST"])
@login_required_analyste
def refuser_suspicion(id_suspicion):
    id_analyste = session.get("user_id")
    commentaire = request.form.get("commentaire", None)
    ok = set_suspicion_decision(id_suspicion, id_analyste, "refusee", commentaire)
    if ok:
        flash("Suspicion marquée comme 'refusée'.", "warning")
    else:
        flash("Erreur lors de l'opération.", "danger")
    return redirect(url_for("dashboard"))


# =========================
#  Lancement du serveur
# =========================
if __name__ == "__main__":
    app.run(debug=True)
















