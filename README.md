# MealFlavor - Guide de demarrage (Front + Backend)

Ce README est destine a un collaborateur qui veut cloner le projet sur GitHub et le faire tourner en local.

## Prerequis
- Node.js 18+
- Flutter (stable)
- PostgreSQL 14+
- (Optionnel) Prisma CLI global

---

## 1) Backend (mealflavor_backend)

### Installation
```bash
cd mealflavor_backend
npm install
```

### Configuration .env
Creer un fichier `.env` dans `mealflavor_backend` avec les variables suivantes:

```env
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/mealflavor?schema=public"
JWT_SECRET="change_me"
JWT_EXPIRES_IN="1h"

# Stripe (optionnel pour paiement en ligne)
STRIPE_SECRET_KEY=""
STRIPE_WEBHOOK_SECRET=""
STRIPE_SUCCESS_URL="http://localhost:3000/payment/success?session_id={CHECKOUT_SESSION_ID}"
STRIPE_CANCEL_URL="http://localhost:3000/payment/cancel"
STRIPE_CURRENCY="xof"

# Cloudinary (optionnel pour upload d'image)
CLOUDINARY_CLOUD_NAME=""
CLOUDINARY_API_KEY=""
CLOUDINARY_API_SECRET=""

# Dev: expose le token de reset dans la reponse
DEV_SHOW_RESET_TOKEN="true"
```

### Base de donnees / Prisma
```bash
npx prisma generate
npx prisma migrate dev
```

Optionnel (donnees de test):
```bash
npm run seed
```

### Lancer le serveur
```bash
npm run dev
```

Serveur par defaut: `http://localhost:3000`

---

## 2) Frontend (front)

### Installation
```bash
cd front
flutter pub get
```

### Configurer l'URL backend
Fichier: `front/lib/core/providers/dio_provider.dart`

Modifier `baseUrl` pour qu'il pointe sur la machine qui tourne le backend:
- Emulateur Android: `http://10.0.2.2:3000/api`
- Simulateur iOS: `http://localhost:3000/api`
- Device physique: `http://IP_DE_LA_MACHINE:3000/api`

### Lancer l'app
```bash
flutter run
```

---

---

## Structure des dossiers
- `front/` : application Flutter
- `mealflavor_backend/` : API Node/Express + Prisma

