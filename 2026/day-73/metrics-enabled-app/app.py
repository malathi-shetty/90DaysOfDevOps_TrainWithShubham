from flask import Flask
from prometheus_client import Counter, generate_latest
from prometheus_client import CONTENT_TYPE_LATEST

app = Flask(__name__)

requests_total = Counter(
    "app_requests_total",
    "Total requests received"
)

@app.route("/")
def home():
    requests_total.inc()
    return "Hello from Prometheus Demo!"

@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {
        "Content-Type": CONTENT_TYPE_LATEST
    }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)