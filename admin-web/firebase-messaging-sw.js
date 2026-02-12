importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  // marry-queen Firebase project
  // Environment variables (process.env) DO NOT work in Service Workers
  apiKey: "AIzaSyCuZHbiZlBfJmqFFHUkkIcipOS0WhmAfVM",
  authDomain: "marry-queen.firebaseapp.com",
  databaseURL: "https://marry-queen-default-rtdb.firebaseio.com",
  projectId: "marry-queen",
  storageBucket: "marry-queen.firebasestorage.app",
  messagingSenderId: "229108556395",
  appId: "1:229108556395:web:f0cad17cc59b41f343c72e",
  measurementId: "G-18FNN8LL7B"
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