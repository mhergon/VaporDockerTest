# ===================================
# Imagen de construcción
# ===================================
FROM swift:6.0-noble AS build

# Actualizar el sistema e instalar dependencias
RUN apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y nginx

# Instalar Vapor Toolbox
RUN apt-get -q install -y curl \
    && curl -sL https://github.com/vapor/toolbox/releases/latest/download/vapor-ubuntu -o /usr/local/bin/vapor \
    && chmod +x /usr/local/bin/vapor

# Preparar directorio de trabajo
WORKDIR /build

# Copiar archivos de dependencias y resolverlas
COPY ./Package.* ./
RUN swift package resolve

# Copiar todo el proyecto
COPY . .

# Construir la aplicación en modo release
RUN swift build -c release --product App

# Crear directorios staging para Resources y Public si existen
RUN mkdir -p /staging/Public /staging/Resources
# Intentar copiar contenido si existe (no falla si no existen)
RUN if [ -d Public ]; then cp -R Public/* /staging/Public/ || true; fi
RUN if [ -d Resources ]; then cp -R Resources/* /staging/Resources/ || true; fi

# ===================================
# Imagen de ejecución
# ===================================
FROM swift:6.0-noble-slim

# Instalar nginx
RUN apt-get -q update \
    && apt-get -q install -y nginx \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio para la aplicación
WORKDIR /app

# Copiar el ejecutable compilado
COPY --from=build /build/.build/release/App .

# Crear directorios para los recursos
RUN mkdir -p ./Public ./Resources

# Copiar directorios desde staging (ahora siempre existirán)
COPY --from=build /staging/Public/ ./Public/
COPY --from=build /staging/Resources/ ./Resources/

# Exponer puerto
EXPOSE 8080

# Iniciar la aplicación (usando formato de array JSON para CMD)
CMD ["sh", "-c", "service nginx start && ./App serve --env production --hostname 0.0.0.0 --port 8080"]