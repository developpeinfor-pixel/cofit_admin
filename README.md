# cofit_admin

Application Flutter pour l'administration Cofit.

## Prerequis

- Flutter 3.35+
- Backend `cofit-backend` demarre

## Configuration API

L'app lit `API_BASE_URL` via `--dart-define`.

Exemples:

- Android emulator: `http://10.0.2.2:3000/api/v1`
- iOS simulator / desktop / web local: `http://localhost:3000/api/v1`
- Appareil reel: `http://<IP_LAN_DE_TA_MACHINE>:3000/api/v1`

## Lancer en local

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

## Build web (exemple)

```bash
flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

## Deploiement Vercel

Le projet contient deja `vercel.json` et `scripts/vercel-build.sh`.

Dans Vercel, configure:

- Environment Variable: `API_BASE_URL` = `https://<ton-backend-render>/api/v1`
- Build Command: laisse celle de `vercel.json`
- Output Directory: laisse `build/web`

Puis lance le deploy.
