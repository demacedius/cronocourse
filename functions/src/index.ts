import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';
import express from 'express';

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Express app
const app = express();

// Stripe Payment Function
export const processStripePayment = functions.https.onCall(async (request) => {
  try {
    const { amount } = request.data;
    // Add your Stripe payment logic here
    return { success: true, clientSecret: 'your_stripe_client_secret' };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Payment processing failed');
  }
});

// Category Update Function
export const handleCategoryUpdate = functions.firestore.onDocumentUpdated(
  'categories/{categoryId}',
  async (event) => {
    const newData = event.data?.after.data();
    const previousData = event.data?.before.data();

    if (newData?.name !== previousData?.name) {
      const productsRef = admin.firestore().collection('products');
      const productsSnapshot = await productsRef
        .where('categoryId', '==', event.params.categoryId)
        .get();

      const batch = admin.firestore().batch();
      productsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, { categoryName: newData?.name });
      });

      await batch.commit();
    }
  }
);

// Order Status Change Function
export const handleOrderStatusChange = functions.firestore.onDocumentUpdated(
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
export const handleNewOrder = functions.firestore.onDocumentCreated(
  'orders/{orderId}',
  async (event) => {
    const orderData = event.data?.data();
    // Add your notification logic here
    console.log(`New order created: ${event.params.orderId}`);
  }
);

// Health check endpoint
app.get('/', (req, res) => {
  res.status(200).send('OK');
});

// Export the Express app as a Firebase Function
export const api = functions.https.onRequest(app); 