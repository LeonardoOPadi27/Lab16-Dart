# StockLab

Aplicación móvil para controlar el inventario y los préstamos de equipos de un laboratorio. El cliente está desarrollado con Flutter y consume una API REST local construida con Node.js, Express y SQLite.

## Funcionalidades

- Dashboard con disponibilidad y movimientos activos.
- CRUD de equipos con búsqueda, estados y control de existencias.
- Registro y edición de préstamos.
- Devoluciones que actualizan el inventario automáticamente.
- Historial de préstamos y filtros por estado.
- Validaciones en la aplicación y en la API.
- Manejo visual de carga, errores y confirmaciones.

## Estructura

```text
lib/
  core/          # Configuración y tema visual
  data/          # Modelos y acceso a la API
  presentation/  # Pantallas y componentes reutilizables
backend/
  src/
    config/       # SQLite y esquema de datos
    controllers/  # Reglas de cada recurso
    middleware/   # Errores y respuestas comunes
    routes/       # Endpoints REST
    validators/   # Validación de entradas
  test/           # Pruebas del backend
```

## Requisitos

- Flutter 3.35 o posterior.
- Node.js 20 o posterior.
- Android Studio, emulador Android o celular físico.

## Ejecutar la API

```bash
cd backend
npm install
npm run dev
```

La API se ejecuta en `http://localhost:3000/api` y crea automáticamente `backend/data/stocklab.db` con algunos equipos de ejemplo.

Comprobación rápida:

```text
GET http://localhost:3000/api/health
```

## Ejecutar Flutter

En un emulador Android:

```bash
flutter pub get
flutter run
```

La aplicación usa `http://10.0.2.2:3000/api` por defecto, que es la dirección del equipo anfitrión desde el emulador Android.

En un celular físico, conecta el celular y la computadora a la misma red Wi-Fi. Averigua la IPv4 de la computadora con `ipconfig` y ejecuta:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.X.X:3000/api
```

Si Windows pregunta por el acceso de Node.js a la red privada, debes permitirlo.

## Endpoints principales

```text
GET    /api/equipment
GET    /api/equipment/:id
POST   /api/equipment
PUT    /api/equipment/:id
DELETE /api/equipment/:id

GET    /api/loans
POST   /api/loans
PUT    /api/loans/:id
PATCH  /api/loans/:id/return
DELETE /api/loans/:id
```

## Verificación

```bash
flutter analyze
flutter test

cd backend
npm test
```
