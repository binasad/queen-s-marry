const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { query, pool } = require('./config/db');

async function diagnoseTokenIssue() {
  console.log('🔍 DIAGNOSING TOKEN ISSUE\n');
  console.log('='.repeat(60));
  
  try {
    // 1. Check if any tokens exist
    console.log('\n1️⃣ Checking for tokens in database...');
    const allTokens = await query(
      `SELECT email, reset_password_token, reset_password_expires, 
       LENGTH(reset_password_token) as token_length
       FROM users 
       WHERE reset_password_token IS NOT NULL 
       ORDER BY reset_password_expires DESC 
       LIMIT 10`
    );
    
    console.log(`   Found ${allTokens.rows.length} token(s) in database\n`);
    
    if (allTokens.rows.length === 0) {
      console.log('❌ PROBLEM: No tokens found in database!');
      console.log('   This means tokens are NOT being stored when emails are sent.\n');
      console.log('   Check the sendWelcomeEmail function logs when assigning a role.');
      return;
    }
    
    // 2. Show all tokens
    console.log('2️⃣ Tokens in database:');
    allTokens.rows.forEach((row, index) => {
      console.log(`\n   Token ${index + 1}:`);
      console.log(`   Email: ${row.email}`);
      console.log(`   Token (first 16): ${row.reset_password_token ? row.reset_password_token.substring(0, 16) + '...' : 'NULL'}`);
      console.log(`   Token length: ${row.token_length}`);
      console.log(`   Expires: ${row.reset_password_expires}`);
      console.log(`   Is expired: ${new Date(row.reset_password_expires) < new Date() ? 'YES ❌' : 'NO ✅'}`);
    });
    
    // 3. Test the specific token from the error
    const testToken = '441db2f2261dde1942098c9532a4d940bdc69d2fdddfb6b85f6ab2f8e0c934b8';
    console.log(`\n3️⃣ Testing token from error: ${testToken.substring(0, 16)}...`);
    
    const tokenMatch = await query(
      'SELECT email, reset_password_token, reset_password_expires FROM users WHERE reset_password_token = $1',
      [testToken]
    );
    
    if (tokenMatch.rows.length > 0) {
      console.log('   ✅ Token FOUND in database!');
      const match = tokenMatch.rows[0];
      console.log(`   Email: ${match.email}`);
      console.log(`   Expires: ${match.reset_password_expires}`);
      console.log(`   Is expired: ${new Date(match.reset_password_expires) < new Date() ? 'YES ❌' : 'NO ✅'}`);
    } else {
      console.log('   ❌ Token NOT FOUND in database');
      console.log('\n   Checking for similar tokens...');
      
      // Check if any token starts with the same prefix
      const similarTokens = await query(
        `SELECT email, reset_password_token, reset_password_expires 
         FROM users 
         WHERE reset_password_token LIKE $1 
         LIMIT 5`,
        [testToken.substring(0, 16) + '%']
      );
      
      if (similarTokens.rows.length > 0) {
        console.log(`   Found ${similarTokens.rows.length} token(s) starting with same prefix:`);
        similarTokens.rows.forEach(row => {
          console.log(`   - ${row.email}: ${row.reset_password_token.substring(0, 16)}...`);
        });
      } else {
        console.log('   No similar tokens found.');
      }
    }
    
    // 4. Check database column type
    console.log('\n4️⃣ Checking database column type...');
    const columnInfo = await query(`
      SELECT 
        column_name, 
        data_type, 
        character_maximum_length,
        is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      AND column_name = 'reset_password_token'
    `);
    
    if (columnInfo.rows.length > 0) {
      const col = columnInfo.rows[0];
      console.log(`   Column type: ${col.data_type}`);
      console.log(`   Max length: ${col.character_maximum_length || 'N/A'}`);
      console.log(`   Nullable: ${col.is_nullable}`);
      
      if (col.character_maximum_length && col.character_maximum_length < 64) {
        console.log(`\n   ⚠️ WARNING: Column max length is ${col.character_maximum_length}, but tokens are 64 chars!`);
        console.log('   Tokens might be getting truncated!');
      }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('\n✅ Diagnosis complete!');
    
  } catch (err) {
    console.error('\n❌ Error during diagnosis:', err);
    console.error(err.stack);
  } finally {
    await pool.end();
  }
}

diagnoseTokenIssue();
