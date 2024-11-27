# Usa la imagen base de Python
FROM python:3.9-slim

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar los archivos necesarios al contenedor
COPY . /app

# Actualizar e instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    procps \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar las dependencias de Python
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Asegurarse de que los scripts sean ejecutables
RUN chmod +x ./linux_monitor/app.sh

# Exponer el puerto 8080 para Gunicorn
EXPOSE 8080

# Comando para ejecutar Gunicorn con la aplicación Flask
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
