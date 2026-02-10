importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  // HARDCODE these keys here. 
  // Environment variables (process.env) DO NOT work in Service Workers
  apiKey: "AIzaSyBSkx7HtbPyp8yuK8uycA9WO1svzjsW65s",
  authDomain: "salon-app-7b3f5.firebaseapp.com",
  databaseURL: "https://salon-app-7b3f5-default-rtdb.firebaseio.com",
  projectId: "salon-app-7b3f5",
  storageBucket: "salon-app-7b3f5.firebasestorage.app",
  messagingSenderId: "219343461160",
  appId: "1:219343461160:web:03a6531e4aecb151bbce1d",
  measurementId: "G-CRHQ39JZ2J"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Background Message:', payload);
  const { title, body } = payload.notification;
  
  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/icon-192x192.png' // Make sure this image exists in /public/icons
  });
});