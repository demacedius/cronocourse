const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');

admin.initializeApp();

const app = express();

// Fonction pour mettre à jour les produits lors du changement de catégorie
exports.updateProductsOnCategoryChange = functions.firestore
  .document('categories/{categoryId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();

    // Vérifier si le nom de la catégorie a changé
    if (newData.name !== previousData.name) {
      const categoryId = context.params.categoryId;
      const newName = newData.name;

      // Mettre à jour tous les produits de cette catégorie
      const productsSnapshot = await admin.firestore()
        .collection('products')
        .where('categoryId', '==', categoryId)
        .get();

      const batch = admin.firestore().batch();
      
      productsSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          categoryName: newName
        });
      });

      return batch.commit();
    }

    return null;
  });

// Route de base pour le health check
app.get('/', (req, res) => {
  res.status(200).send('OK');
});

// Exporter l'application Express
exports.api = functions.https.onRequest(app); 