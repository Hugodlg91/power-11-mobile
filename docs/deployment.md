# Guide de Déploiement Android - Power-11 Mobile

Ce guide t'explique comment lancer le jeu sur ton téléphone Android depuis Godot 4.

## Méthode 1 : "One-Click Deploy" (Le plus rapide pour tester) ⚡

C'est la méthode idéale pour tester rapidement pendant le développement.

### Prérequis
1.  **Sur ton téléphone** :
    *   Activer le **Mode Développeur** (Tapote 7 fois sur "Numéro de build" dans Paramètres > À propos).
    *   Activer le **Débogage USB** dans les Options pour les développeurs.
    *   Connecter le téléphone au PC via USB.

### Configuration Godot
1.  Ouvre Godot.
2.  Si tout est ok, tu devrais voir une petite icône **Android** apparaître en haut à droite de l'éditeur (à côté des boutons Play/Pause/Stop).
3.  Clique dessus !
4.  Le jeu va s'installer et se lancer directement sur ton téléphone.

---

## Méthode 2 : Export APK (Pour installer "proprement") 📦

Si tu veux envoyer le jeu à un ami ou l'installer définitivement.

### 1. Installer les SDK Android
Godot a besoin du SDK Android et de Java (OpenJDK 17 recommandé).
*   Dans Godot : `Editor` > `Manage Export Templates` -> Télécharger les templates.
*   Dans Godot : `Editor` > `Editor Settings` > `Export` > `Android`.
    *   Tu dois renseigner le chemin vers `adb.exe` (Android SDK) et `jarsigner` (Java).

### 2. Créer un Preset
1.  Menu **Project > Export**.
2.  Clique sur **Add...** > **Android**.
3.  Tu verras des erreurs en rouge (il faut configurer le Keystore).
    *   Pour le debug, Godot génère une clé par défaut. Clique sur le bouton "Fix Import" ou configure le chemin du `debug.keystore`.

### 3. Exporter
1.  Une fois les erreurs en rouge disparues, clique sur **Export Project**.
2.  Décoche "Export With Debug" si c'est pour une release finale (nécessite une vraie clé signée).
3.  Choisis l'emplacement (ex: `builds/power-11.apk`).
4.  Envoie l'APK sur ton téléphone et installe-le !

## Troubleshooting 🔧
*   **Pas d'icône Android ?** Vérifie tes drivers USB et que le câble est bien un câble de *données* (pas juste charge).
*   **Écran noir ?** Vérifie que tu es bien en "Compatibility" (GLES3/OpenGL ES 3.0) dans les réglages du projet (ce qui est le cas pour ce projet).

Bon jeu ! 📱
