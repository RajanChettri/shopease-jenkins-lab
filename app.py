import os
from flask import Flask, jsonify

app = Flask(__name__)

PRICES = {"laptop": 55000, "headphones": 2500, "keyboard": 1200}


@app.route("/")
def home():
    return jsonify(service="shopease-api",
                   version=os.getenv("APP_VERSION", "dev"),
                   environment=os.getenv("APP_ENV", "local"))


@app.route("/health")
def health():
    return jsonify(status="ok",
                   version=os.getenv("APP_VERSION", "dev"),
                   environment=os.getenv("APP_ENV", "local"))


@app.route("/price/<item>")
def price(item):
    if item not in PRICES:
        return jsonify(error="unknown item"), 404
    return jsonify(item=item, price=PRICES[item], currency="INR")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
