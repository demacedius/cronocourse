const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const express = require('express');
const stripe = require('stripe');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Express app
const app = express();

// Stripe Payment Function
exports.initStripePayment = functions.https.onCall(async (request) => {
  try {
    console.log('Starting payment process...');
    const { amount } = request.data;
    console.log('Amount received:', amount);
    
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    console.log('Stripe key present:', !!stripeSecretKey);
    
    if (!stripeSecretKey) {
      console.error('Stripe secret key not configured');
      throw new functions.https.HttpsError('internal', 'Stripe secret key not configured');
    }

    // Initialize Stripe with the secret key
    const stripeClient = stripe(stripeSecretKey);
    console.log('Stripe client initialized');

    // Create a PaymentIntent
    console.log('Creating payment intent...');
    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: Math.round(amount * 100), // amount in cents
      currency: 'eur',
      automatic_payment_methods: {
        enabled: true,
      },
    });
    console.log('Payment intent created:', paymentIntent.id);

    return { 
      success: true, 
      clientSecret: paymentIntent.client_secret 
    };
  } catch (error) {
    console.error('Stripe payment error:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      type: error.type
    });
    throw new functions.https.HttpsError('internal', error.message || 'Payment processing failed');
  }
});

// Category Update Function
exports.handleCategoryUpdate = functions.firestore.onDocumentUpdated(
  'category/{categoryId}',
  async (event) => {
    const newData = event.data?.after.data();
    const previousData = event.data?.before.data();

    // Vérifier si le nom de la catégorie a changé
    if (newData?.name !== previousData?.name) {
      console.log(`Category name changed from ${previousData?.name} to ${newData?.name}`);

      // Récupérer tous les produits de l'ancienne catégorie
      const productsRef = admin.firestore().collection('product');
      const productsSnapshot = await productsRef
        .where('category', '==', previousData?.name)
        .get();

      console.log(`Found ${productsSnapshot.size} products to update`);

      // Mettre à jour les produits en batch
      const batch = admin.firestore().batch();
      productsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, { 
          category: newData?.name,
          categoryId: event.params.categoryId
        });
      });

      try {
        await batch.commit();
        console.log(`Successfully updated ${productsSnapshot.size} products`);
      } catch (error) {
        console.error('Error updating products:', error);
        throw error;
      }
    }
  }
);

// Order Status Change Function
exports.handleOrderStatusChange = functions.firestore.onDocumentUpdated(
  'orders/{orderId}',
  async (event) => {
    const newData = event.data?.after.data();
    const previousData = event.data?.before.data();

    if (newData?.status !== previousData?.status) {
      // Add your notification logic here
      console.log(`Order ${event.params.orderId} status changed to ${newData?.status}`);
    }
  }
);

// New Order Function
exports.handleNewOrder = functions.firestore.onDocumentCreated(
  'users/{userId}/orderedProduct/{orderId}',
  async (event) => {
    const orderData = event.data?.data();
    console.log(`New order created: ${event.params.orderId}`);

    // Récupérer les produits de la commande
    const productsRef = admin.firestore().collection('product');
    const products = await Promise.all(
      orderData.products.map(async (product) => {
        const productDoc = await productsRef.doc(product.id).get();
        return {
          ...product,
          restaurantId: productDoc.data()?.restaurantId
        };
      })
    );

    // Récupérer les IDs des restaurants concernés
    const restaurantIds = [...new Set(products.map(p => p.restaurantId))];

    // Récupérer les restaurateurs associés à ces restaurants
    const restaurateursSnapshot = await admin.firestore()
      .collection('users')
      .where('isRestaurateur', '==', true)
      .where('restaurantId', 'in', restaurantIds)
      .get();

    // Récupérer les tokens FCM des restaurateurs
    const tokens = [];
    for (const doc of restaurateursSnapshot.docs) {
      const tokenDoc = await admin.firestore()
        .collection('addFCMtoken')
        .doc(doc.id)
        .get();
      
      if (tokenDoc.exists) {
        tokens.push(tokenDoc.data()?.token);
      }
    }

    if (tokens.length > 0) {
      // Envoyer la notification
      const message = {
        notification: {
          title: 'Nouvelle commande !',
          body: `Une nouvelle commande a été passée (${orderData?.total}€)`,
        },
        data: {
          orderId: event.params.orderId,
          type: 'new_order'
        },
        tokens: tokens,
      };

      try {
        const response = await admin.messaging().sendMulticast(message);
        console.log('Notifications envoyées:', response.successCount);
      } catch (error) {
        console.error('Erreur lors de l\'envoi des notifications:', error);
      }
    }
  }
);

// Function to update existing users
exports.updateExistingUsers = functions.https.onCall(async (data, context) => {
  try {
    console.log('Starting user update process...');
    
    const usersRef = admin.firestore().collection('users');
    const usersSnapshot = await usersRef.get();
    
    console.log(`Found ${usersSnapshot.size} users to update`);
    
    const batch = admin.firestore().batch();
    let count = 0;
    
    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.isRestaurateur === undefined) {
        batch.update(doc.ref, { isRestaurateur: false });
        count++;
      }
    });
    
    if (count > 0) {
      await batch.commit();
      console.log(`Successfully updated ${count} users`);
      return { success: true, updatedCount: count };
    } else {
      console.log('No users needed updating');
      return { success: true, updatedCount: 0 };
    }
  } catch (error) {
    console.error('Error updating users:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Health check endpoint
app.get('/', (req, res) => {
  res.status(200).send('OK');
});

// Export the Express app as a Firebase Function
exports.api = functions.https.onRequest(app);
