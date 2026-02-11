import { initializeApp, getApps, getApp } from "firebase/app";
import { getMessaging, getToken, isSupported } from "firebase/messaging";

const firebaseConfig = {
  apiKey: "AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM",
  authDomain: "marry-queen.firebaseapp.com",
  projectId: "marry-queen",
  storageBucket: "marry-queen.firebasestorage.app",
  messagingSenderId: "229108556395",
  appId: "1:229108556395:web:f0cad17cc59b41f343c72e",
  measurementId: "G-18FNN8LL7B"
};

// Initialize Firebase only once
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

export async function getFcmToken(vapidKey: string) {
  if (typeof window === 'undefined' || !('serviceWorker' in navigator)) return null;
  const supported = await isSupported();
  if (!supported) return null;
  const messaging = getMessaging(app);
  try {
    const token = await getToken(messaging, { vapidKey });
    return token;
  } catch (err) {
    console.error('Failed to get FCM token:', err);
    return null;
  }
}
