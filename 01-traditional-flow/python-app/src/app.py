import os
from flask import Flask, send_from_directory, jsonify

# Directorio donde viven los archivos estáticos (public/), relativo a este archivo
PUBLIC_DIR = os.path.join(os.path.dirname(__file__), "public")

# Instancia de Flask expuesta a nivel de módulo para que pytest-flask pueda importarla
app = Flask(__name__, static_folder="public", static_url_path="")


@app.route("/")
def index():
    """Sirve la Interfaz Web desde la carpeta public/."""
    return send_from_directory(PUBLIC_DIR, "index.html")


@app.route("/health")
def health():
    """Health endpoint — retorna estado del servicio con HTTP 200."""
    return jsonify({"status": "UP", "charla": "Despliegue 101 on Python"}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 80))
    app.run(host="0.0.0.0", port=port)
