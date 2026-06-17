# Configurer Supabase (backend gratuit)

Supabase est la base de données qui stocke tous vos messages. 5 minutes maxi.

---

## Étape 1 : Créer ton projet Supabase

1. Va sur supabase.com et crée un compte gratuit
2. Clique sur "New project"
3. Donne un nom : `gangsms`
4. Choisis un mot de passe fort (note-le quelque part)
5. Région : Europe West (ou la plus proche)
6. Clique "Create new project" et attends 1-2 minutes

---

## Étape 2 : Créer les tables

1. Dans ton projet Supabase, clique sur "SQL Editor" dans le menu gauche
2. Clique sur "New query"
3. Colle exactement ce SQL et clique "Run" :

```sql
-- Table des messages
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id TEXT NOT NULL,
  sender TEXT NOT NULL,
  content TEXT,
  type TEXT NOT NULL DEFAULT 'text',
  file_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table de présence (qui est en ligne)
CREATE TABLE presence (
  pseudo TEXT PRIMARY KEY,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  current_room TEXT
);

-- Autoriser tout le monde à lire et écrire (l'accès est protégé par le code secret dans l'app)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Accès libre messages" ON messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Accès libre presence" ON presence FOR ALL USING (true) WITH CHECK (true);

-- Activer le temps réel sur les messages
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

---

## Étape 3 : Créer le bucket de stockage (images + audio)

1. Dans le menu gauche, clique sur "Storage"
2. Clique "New bucket"
3. Nom : `media`
4. Coche "Public bucket"
5. Clique "Save"

---

## Étape 4 : Récupérer tes clés API

1. Dans le menu gauche, clique sur "Project Settings" (icône engrenage)
2. Clique sur "API"
3. Copie :
   - "Project URL" (commence par https://...)
   - "anon public" (commence par eyJ...)

---

## Étape 5 : Mettre les clés dans l'app

Ouvre le fichier `lib/config.dart` et remplace les deux lignes :

```dart
const String kSupabaseUrl = 'REMPLACER_PAR_TON_URL';
const String kSupabaseAnonKey = 'REMPLACER_PAR_TA_CLE';
```

Par tes vraies valeurs :

```dart
const String kSupabaseUrl = 'https://xxxxxxxxxxxx.supabase.co';
const String kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5...';
```

---

## Étape 6 : Compiler et télécharger l'APK

Voir GUIDE_INSTALLATION.md
