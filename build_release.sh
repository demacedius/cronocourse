#!/bin/bash

# Incrémenter la version
./increment_version.sh

# Construire l'application
flutter build appbundle --release

echo "Build terminé avec la nouvelle version" 