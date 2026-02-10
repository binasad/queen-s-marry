// Simple test script to verify backend is accessible
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/health',
  method: 'GET',
};

console.log('Testing backend connection...');
console.log('URL: http://localhost:5000/health');

const req = http.request(options, (res) => {
  console.log(`✅ Status Code: ${res.statusCode}`);
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('✅ Response:', data);
    console.log('\n✅ Backend is accessible from localhost!');
    console.log('\n💡 If Android emulator still can\'t connect:');
    console.log('   1. Check Windows Firewall - allow Node.js for private networks');
    console.log('   2. Try using your computer\'s IP address instead of 10.0.2.2');
    console.log('   3. Make sure both devices are on the same network');
  });
});

req.on('error', (error) => {
  console.error('❌ Connection failed:', error.message);
  console.log('\n💡 Make sure the backend server is running:');
  console.log('   cd backend && npm run dev');
});

req.end();
