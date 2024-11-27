from flask import Flask, render_template, request, jsonify
import subprocess
import platform
import os

app = Flask(__name__)

# Rutas para Linux o Windows
IS_WINDOWS = platform.system() == "Windows"


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/processes")
def processes():
    try:
        if IS_WINDOWS:
            # Ejecutar el script PowerShell para obtener procesos
            print("POWERSHELL")
            result = subprocess.run(
                ["powershell", "-Command",
                    "& { . ./windows_monitor/app.ps1; Get-ProcessTable }"],
                capture_output=True,
                text=True
            )
        else:
            # Ejecutar el script Bash para obtener procesos
            print("BASH")
            result = subprocess.run(
                ["bash", "./linux_monitor/app.sh", "get_process_table"],
                capture_output=True,
                text=True
            )

        if result.returncode == 0:
            return result.stdout
        else:
            return f"Error: {result.stderr}", 500
    except Exception as e:
        return str(e), 500


@app.route("/terminate", methods=["POST"])
def terminate():
    pid = request.json.get("pid")
    if not pid:
        return jsonify({"success": False, "error": "No se especificó un PID"}), 400

    try:
        if IS_WINDOWS:
            # Ejecutar el script PowerShell para terminar procesos
            result = subprocess.run(
                ["powershell", "-File", "./windows_monitor/app.ps1",
                    "Terminate-ProcessById", "-ProcessId", str(pid)],
                capture_output=True,
                text=True
            )
        else:
            # Ejecutar el script Bash para terminar procesos
            result = subprocess.run(
                ["bash", "./linux_monitor/app.sh",
                    "terminate_process", str(pid)],
                capture_output=True,
                text=True
            )

        if result.returncode == 0:
            return jsonify({"success": True, "message": result.stdout.strip()})
        else:
            return jsonify({"success": False, "error": result.stderr.strip()}), 500
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
