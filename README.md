# scan_bibli

Application Flutter Android de gestion de bibliothèque personnelle avec scanner de codes-barres ISBN.

## Fonctionnalités

- **Authentification** Supabase (connexion / inscription)
- **Scanner caméra** de codes-barres ISBN (EAN-13, EAN-8, UPC)
- **Saisie manuelle** d'ISBN
- **Recherche multi-sources** : Google Books + BNF (edge function) + Open Library
- **Bibliothèque** avec filtres par statut (À lire, En cours, Lu, Prêté)
- **Filtres par rangement** (R1/R2)
- **Recherche** par titre, auteur, ISBN
- **Fiche détaillée** complète et éditable (données BNF enrichies)
- **Photo de couverture** via caméra
- **Export CSV** de la collection

## Structure

```
lib/
├── main.dart                    # Entry point + Supabase init + AuthGate
├── theme.dart                   # Design tokens, couleurs, typo
├── models/
│   └── book.dart                # Modèle Book (JSON <-> Supabase)
├── services/
│   ├── auth_service.dart        # Authentification Supabase
│   ├── book_service.dart        # CRUD livres Supabase
│   └── isbn_service.dart        # Lookup ISBN multi-sources
└── screens/
    ├── auth_screen.dart          # Écran connexion / inscription
    ├── home_screen.dart          # Shell avec bottom nav
    ├── scanner_screen.dart       # Scanner caméra + ISBN manuel
    ├── scan_result_sheet.dart    # Bottom sheet résultat scan
    ├── library_screen.dart       # Liste biblio + filtres + export
    └── book_detail_screen.dart   # Fiche détaillée éditable
```

## Build

```bash
flutter pub get
flutter build apk --debug
```

L'APK se trouve dans `build/app/outputs/flutter-apk/app-debug.apk`.

## Codemagic

Le fichier `codemagic.yaml` est configuré pour un build automatique.
Poussez sur GitHub et connectez le repo à Codemagic.
