# Imagen base oficial de Flutter con Android SDK
FROM ghcr.io/cirruslabs/flutter:stable

# Instalar dependencias adicionales necesarias (libGL, Firebase CLI)
USER root
RUN apt-get update && \
    apt-get install -y libgl1 libstdc++6 curl unzip && \
    curl -sL https://firebase.tools | bash

# Crear y usar directorio de trabajo
WORKDIR /app

# Copiar archivos del proyecto
COPY . .

# Instalar dependencias de Flutter
RUN flutter pub get

# Exponer el puerto para web (si se usa)
EXPOSE 8080

# Comando por defecto (puede usarse para desarrollo interactivo)
CMD ["/bin/bash"]

