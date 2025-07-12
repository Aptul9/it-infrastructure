from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Welcome to the URL Echo Application. Add any path after the domain to see it echoed back."

@app.route('/<path:subpath>')
def echo_url(subpath):
    return subpath

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)