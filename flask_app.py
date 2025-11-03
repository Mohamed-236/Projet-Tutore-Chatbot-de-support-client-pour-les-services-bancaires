# Pour tester que tout fonctionne normalement
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello, chatbot bancaire !"

if __name__ == "__main__":
    app.run(debug=True)
