// Node.js script to check tokens in database
// Run with: node scripts/check-tokens.js

require('dotenv').config();
const { query } = require('../src/config/db');

async function checkTokens() {
  try {
    console.log('🔍 Checking tokens in database...\n');

    // Get all users with tokens
    const result = await query(`
      SELECT 
        email,
        name,
        reset_password_token,
        reset_password_expires,
        CASE 
          WHEN reset_password_expires > CURRENT_TIMESTAMP THEN 'Valid'
          WHEN reset_password_expires IS NOT NULL THEN 'Expired'
          ELSE 'No Token'
        END AS token_status
      FROM users 
      WHERE reset_password_token IS NOT NULL
      ORDER BY reset_password_expires DESC
    `);

    if (result.rows.length === 0) {
      console.log('❌ No tokens found in database!\n');
      console.log('This means tokens are not being stored when emails are sent.');
    } else {
      console.log(`✅ Found ${result.rows.length} token(s):\n`);
      result.rows.forEach((row, index) => {
        console.log(`${index + 1}. Email: ${row.email}`);
        console.log(`   Name: ${row.name}`);
        console.log(`   Token (first 8 chars): ${row.reset_password_token ? row.reset_password_token.substring(0, 8) + '...' : 'NULL'}`);
        console.log(`   Expires: ${row.reset_password_expires}`);
        console.log(`   Status: ${row.token_status}`);
        console.log('');
      });
    }

    // Get counts
    const counts = await query(`
      SELECT 
        COUNT(*) as total_tokens,
        COUNT(*) FILTER (WHERE reset_password_expires > CURRENT_TIMESTAMP) as valid_tokens,
        COUNT(*) FILTER (WHERE reset_password_expires <= CURRENT_TIMESTAMP) as expired_tokens
      FROM users 
      WHERE reset_password_token IS NOT NULL
    `);

    if (counts.rows.length > 0) {
      const count = counts.rows[0];
      console.log('📊 Token Statistics:');
      console.log(`   Total tokens: ${count.total_tokens}`);
      console.log(`   Valid tokens: ${count.valid_tokens}`);
      console.log(`   Expired tokens: ${count.expired_tokens}`);
    }

    // Check a specific email (change this to test)
    const testEmail = process.argv[2];
    if (testEmail) {
      console.log(`\n🔍 Checking token for: ${testEmail}`);
      const userResult = await query(
        'SELECT email, reset_password_token, reset_password_expires FROM users WHERE email = $1',
        [testEmail]
      );
      
      if (userResult.rows.length === 0) {
        console.log(`❌ User not found: ${testEmail}`);
      } else {
        const user = userResult.rows[0];
        console.log(`   Token: ${user.reset_password_token ? user.reset_password_token.substring(0, 16) + '...' : 'NULL'}`);
        console.log(`   Expires: ${user.reset_password_expires || 'NULL'}`);
        if (user.reset_password_token) {
          const isValid = user.reset_password_expires && new Date(user.reset_password_expires) > new Date();
          console.log(`   Status: ${isValid ? '✅ Valid' : '❌ Expired'}`);
        }
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error checking tokens:', error);
    process.exit(1);
  }
}

checkTokens();
