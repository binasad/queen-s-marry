'use client'; // 👈 Important for Next.js App Router

import { useEffect, useState } from 'react';
import { initializeApp, getApps, getApp } from 'firebase/app';
import { getMessaging, getToken, isSupported } from 'firebase/messaging';
import axios from 'axios';

// 1. Your Firebase Config (Safe to expose public keys)
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

const useFcmToken = () => {
  const [token, setToken] = useState<string | null>(null);
  const [permission, setPermission] = useState<NotificationPermission>('default');

  useEffect(() => {
    const retrieveToken = async () => {
      try {
        // 2. Prevent execution on Server Side
        if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
          
          // 3. Initialize Firebase only if not already initialized
          const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
          
          // 4. Check if messaging is supported in this browser
          const messagingSupported = await isSupported();
          if (!messagingSupported) return;

          const messaging = getMessaging(app);

          // 5. Request User Permission
          const permissionResult = await Notification.requestPermission();
          setPermission(permissionResult);

          if (permissionResult === 'granted') {
            const currentToken = await getToken(messaging, {
              vapidKey: process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY, // From Firebase Console -> Cloud Messaging
            });

            if (currentToken) {
              console.log('🔥 FCM Token:', currentToken);
              setToken(currentToken);
              
              // 6. Automatically sync to backend
              await saveTokenToBackend(currentToken);
            }
          }
        }
      } catch (error) {
        console.error('Error retrieving FCM token:', error);
      }
    };

    retrieveToken();
  }, []);

  return { token, permission };
};

// Helper to call your backend
async function saveTokenToBackend(token: string) {
  try {
    // You typically send this along with the User ID (via Auth header)
    await axios.post('/api/notifications/save-token', { fcmToken: token });
    console.log('✅ Token saved to server');
  } catch (error) {
    console.error('❌ Failed to save token:', error);
  }
}

export default useFcmToken;