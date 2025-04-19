const { onCall } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
require('dotenv').config
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY); // ta clé stripe

initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Fonction de paiement
exports.initStripePayment = onCall({ region: 'europe-west1' }, async (request) => {
  const amount = request.data.amount;

  if (!amount || amount <= 0) {
    throw new Error("Montant invalide.");
  }

  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 100),
    currency: 'eur',
    automatic_payment_methods: { enabled: true },
    metadata: { source: 'app' },
  });

  return {
    clientSecret: paymentIntent.client_secret,
  };
});

// Notification à la mise à jour du statut
exports.notifyStatusChange = onDocumentUpdated("users/{userId}/orderedProduct/{orderId}", async (event) => {
  const beforeStatus = event.data.before.data()?.status;
  const afterStatus = event.data.after.data()?.status;

  if (beforeStatus === afterStatus) return;

  const userId = event.params.userId;
  const tokenDoc = await db.collection("addFCMtoken").doc(userId).get();
  const fcmToken = tokenDoc.data()?.token;

  if (!fcmToken) {
    console.log(`Aucun token FCM pour l'utilisateur ${userId}`);
    return;
  }

  const payload = {
    notification: {
      title: "Commande mise à jour",
      body: `Le statut de votre commande est : ${afterStatus}`,
    },
    token: fcmToken,
  };

  try {
    const response = await messaging.send(payload);
    console.log("✅ Notification envoyée :", response);
  } catch (error) {
    console.error("❌ Erreur d'envoi :", error);
  }
});

const { onDocumentCreated } = require("firebase-functions/v2/firestore");

// Notification pour les administrateurs à chaque nouvelle commande
exports.notifyAdminOnNewOrder = onDocumentCreated("users/{userId}/orderedProduct/{orderId}", async (event) => {
  const userId = event.params.userId;

  // Récupère tous les utilisateurs avec admin == true
  const adminSnapshot = await db.collection("users").where("admin", "==", true).get();
  const tokens = [];

  for (const adminDoc of adminSnapshot.docs) {
    const adminId = adminDoc.id;
    const tokenSnap = await db.collection("addFCMtoken").doc(adminId).get();
    const token = tokenSnap.data()?.token;
    if (token) tokens.push(token);
  }

  if (tokens.length === 0) {
    console.log("Aucun administrateur avec token FCM.");
    return;
  }

  const payload = {
    notification: {
      title: "Nouvelle commande 🛒",
      body: `Un client a passé une nouvelle commande.`,
    },
    tokens: tokens,
  };

  try {
    const response = await messaging.sendEachForMulticast(payload);
    console.log("✅ Notification envoyée aux admins :", response);
  } catch (error) {
    console.error("❌ Erreur d'envoi aux admins :", error);
  }
});
