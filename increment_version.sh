#!/bin/bash

# Lire le fichier pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | cut -d '+' -f 2 | tr -d ' ')

# Incrémenter le numéro de build
NEW_VERSION=$((VERSION + 1))

# Mettre à jour le fichier pubspec.yaml
sed -i '' "s/version: .*/version: 1.0.0+$NEW_VERSION/" pubspec.yaml

echo "Version incrémentée à 1.0.0+$NEW_VERSION" 