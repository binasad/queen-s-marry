/**
 * marry-queen Firebase project config (for reference)
 * The backend uses firebase-admin with a service account file (firebase-admin-sdk.json)
 * Download it from: Firebase Console → marry-queen → Project Settings → Service Accounts
 * Replace firebase-admin-sdk.json with the new file from marry-queen project
 */
const firebaseConfig = {
  apiKey: "AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM",
  authDomain: "marry-queen.firebaseapp.com",
  projectId: "marry-queen",
  storageBucket: "marry-queen.firebasestorage.app",
  messagingSenderId: "229108556395",
  appId: "1:229108556395:web:f0cad17cc59b41f343c72e",
  measurementId: "G-18FNN8LL7B"
};

module.exports = { firebaseConfig };
