# Installer GangSMS sur vos téléphones

---

## Pré-requis

Avant cette étape, tu dois avoir :
- Suivi GUIDE_SUPABASE.md (clés API dans config.dart)
- Un compte GitHub

---

## Étape 1 : Créer le dépôt GitHub

1. Va sur github.com, connecte-toi
2. Clique "New repository"
3. Nom : `gangsms-app`
4. Public ou Private (les deux marchent)
5. Clique "Create repository"

---

## Étape 2 : Uploader les fichiers

1. Sur la page du dépôt, clique "uploading an existing file"
2. Ouvre l'explorateur : `C:\Users\RAQIIB\OneDrive\Desktop\jarvis\gangsms-app\`
3. Sélectionne tout (Ctrl+A) et glisse dans GitHub
4. Message de commit : `GangSMS initial`
5. Clique "Commit changes"

---

## Étape 3 : Attendre la compilation

1. Clique sur l'onglet "Actions" dans GitHub
2. Tu vois "Build GangSMS APK" en cours (cercle jaune)
3. Attends 8-10 minutes qu'il devienne vert

Si c'est rouge, envoie le message d'erreur à Tina dans le Jarvis.

---

## Étape 4 : Télécharger l'APK

1. Clique sur le job vert "Build GangSMS APK"
2. Tout en bas dans "Artifacts"
3. Clique "gangsms-release" pour télécharger le ZIP
4. Extrais le ZIP, tu obtiens `app-release.apk`

---

## Étape 5 : Installer sur Android

**Sur chaque téléphone Android :**

1. Va dans Paramètres > Sécurité > Installer des apps inconnues
2. Autorise ton navigateur ou gestionnaire de fichiers
3. Transfère `app-release.apk` sur le téléphone (Google Drive, WhatsApp, câble USB)
4. Ouvre le fichier et appuie sur "Installer"
5. L'app GangSMS apparaît sur l'écran d'accueil

---

## Utilisation

1. Ouvre GangSMS
2. Tape le code : `gangsms2026`
3. Choisis ton pseudo
4. Sélectionne un salon et commence à écrire
