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
# Copiar archivos públicos y recursos si existen
COPY --from=build /build/Public ./Public
COPY --from=build /build/Resources ./Resources

# Configurar nginx (opcional, puedes añadir configuración personalizada)
COPY --from=build /build/nginx.conf /etc/nginx/sites-available/default

# Exponer puerto
EXPOSE 8080

# Iniciar la aplicación
CMD service nginx start && ./App serve --env production --hostname 0.0.0.0 --port 8080