# Etap 1: Budowanie (Build)
FROM node:20-alpine AS builder

WORKDIR /app

# Kopiujemy tylko pliki konfiguracyjne, żeby wykorzystać cache Dockera
COPY package.json package-lock.json ./

# Instalujemy zależności
RUN npm ci

# Kopiujemy resztę kodu i budujemy
COPY . .
RUN npm run build

# Etap 2: Serwowanie (Production)
FROM nginx:alpine

# Kopiujemy zbudowaną aplikację z pierwszego etapu
COPY --from=builder /app/dist /usr/share/nginx/html

# Opcjonalnie: własna konfiguracja Nginx (odkomentuj jeśli masz plik nginx.conf)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]