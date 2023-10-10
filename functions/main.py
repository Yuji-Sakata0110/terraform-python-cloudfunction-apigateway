from flask import Flask, request, jsonify, abort

app = Flask(__name__)


@app.route("/", methods=["GET"])
def root() -> str:
    return "index"


@app.route("/route1", methods=["GET"])
def route1() -> str:
    # Handle Route 1 logic
    return jsonify({"message": "Hello from Route 1"})


@app.route("/route2", methods=["POST"])
def route2() -> str:
    # Handle Route 2 logic
    return jsonify({"message": "Hello from Route 2"})


# entry point
def main(request):
    path = request.path

    # routers
    if path == "/":
        return root()
    elif path == "/route1":
        return route1()
    elif path == "/route2":
        return route2()
    else:
        abort(404)


# local debug
if __name__ == "__main__":
    print("---------- local debug start ----------")
    app.run(debug=True, port=8080)
