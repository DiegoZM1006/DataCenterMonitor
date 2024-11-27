from flask import Flask, render_template, request, jsonify
import subprocess
import platform

app = Flask(__name__)

# Función para detectar el sistema operativo
def detect_os():
    """
    Detecta el entorno de ejecución:
    - Si es Windows, devuelve "windows".
    - Si es Linux y es WSL, devuelve "windows" (opcional).
    - Si es Linux, devuelve "linux".
    """
    system = platform.system()
    print(f"Detectando sistema operativo: {system}")
    if system == "Linux" and "microsoft" in platform.release().lower():
        print("Detectado: WSL en Windows. Usando PowerShell.")
        return "windows"
    elif system == "Windows":
        print("Detectado: Windows. Usando PowerShell.")
        return "windows"
    else:
        print("Detectado: Linux. Usando Bash.")
        return "linux"

# Detecta el sistema operativo al inicio de la aplicación
OS_TYPE = detect_os()


@app.route("/")
def index():
    """
    Página principal.
    """
    return render_template("index.html")


@app.route("/processes")
def processes():
    """
    Endpoint para obtener la lista de procesos del sistema.
    """
    try:
        if OS_TYPE == "windows":
            print("Ejecutando PowerShell para obtener procesos...")
            result = subprocess.run(
                ["powershell", "-Command", "& { . ./windows_monitor/app.ps1; Get-ProcessTable }"],
                capture_output=True,
                text=True
            )
        else:
            # Ejecutar el script Bash para obtener procesos
            print("Ejecutando Bash para obtener procesos...")
            result = subprocess.run(
                ["bash", "./linux_monitor/app.sh", "get_process_table"],
                capture_output=True,
                text=True
            )

        # Verificar el resultado
        if result.returncode == 0:
            return result.stdout  # Devuelve la tabla HTML o JSON generado por el script
        else:
            return f"Error al obtener procesos: {result.stderr}", 500
    except Exception as e:
        return str(e), 500


@app.route("/terminate", methods=["POST"])
def terminate():
    """
    Endpoint para terminar un proceso por su PID.
    """
    pid = request.json.get("pid")
    if not pid:
        return jsonify({"success": False, "error": "No se especificó un PID"}), 400

    try:
        if OS_TYPE == "windows":
            # Ejecutar el script PowerShell para terminar procesos
            print(f"Ejecutando PowerShell para terminar el proceso con PID {pid}...")
            result = subprocess.run(
                ["powershell", "-Command", f"& {{ . ./windows_monitor/app.ps1; Stop-ProcessById -ProcessId {pid} }}"],
                capture_output=True,
                text=True
            )
            print(result)
        else:
            # Ejecutar el script Bash para terminar procesos
            print(f"Ejecutando Bash para terminar el proceso con PID {pid}...")
            result = subprocess.run(
                ["bash", "./linux_monitor/app.sh", "terminate_process", str(pid)],
                capture_output=True,
                text=True
            )
            print(result.stdout)

        # Verificar el resultado
        if result.returncode == 0:
            return jsonify({"success": True, "message": result.stdout.strip()})
        else:
            return jsonify({"success": False, "error": result.stderr.strip()}), 500
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


if __name__ == "__main__":
    """
    Ejecutar la aplicación Flask.
    """
    app.run(host="0.0.0.0", port=8080)
