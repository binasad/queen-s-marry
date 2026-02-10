/**
 * Database Setup Script
 * Creates database and tables from schema.sql without requiring psql CLI
 */

require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Database connection config for initial setup
const adminClient = new Client({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
  database: 'postgres', // Connect to default postgres database to create a new one
});

// Main database connection config
const mainClient = new Client({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'salon_db',
});

async function setupDatabase() {
  const dbName = process.env.DB_NAME || 'salon_db';
  const schemaPath = path.join(__dirname, '../../database/schema.sql');

  try {
    // Step 1: Connect to admin database to create the target database
    console.log('📦 Connecting to PostgreSQL admin database...');
    await adminClient.connect();
    console.log('✓ Connected to admin database');

    // Step 2: Check if database exists
    console.log(`\n🔍 Checking if database "${dbName}" exists...`);
    const dbResult = await adminClient.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [dbName]
    );

    if (dbResult.rows.length === 0) {
      // Step 3: Create database if it doesn't exist
      console.log(`📝 Creating database "${dbName}"...`);
      await adminClient.query(`CREATE DATABASE ${dbName}`);
      console.log(`✓ Database "${dbName}" created successfully`);
    } else {
      console.log(`✓ Database "${dbName}" already exists`);
    }

    // Close admin connection
    await adminClient.end();

    // Step 4: Connect to the main database
    console.log(`\n📦 Connecting to database "${dbName}"...`);
    await mainClient.connect();
    console.log('✓ Connected to main database');

    // Step 5: Read schema file
    console.log('\n📖 Reading schema file...');
    const schemaSQL = fs.readFileSync(schemaPath, 'utf-8');

    // Step 6: Execute entire schema as one statement for consistency
    console.log('🔧 Executing schema setup...');
    try {
      await mainClient.query(schemaSQL);
      console.log('✓ Schema executed successfully');
    } catch (error) {
      // Check if error is due to already existing objects
      if (error.message.includes('already exists')) {
        console.log('⚠️  Some objects already exist, continuing...');
      } else {
        throw error;
      }
    }

    // Step 7: Verify tables were created
    console.log('\n📋 Verifying tables...');
    const tableResult = await mainClient.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);

    if (tableResult.rows.length > 0) {
      console.log(`✓ Successfully created ${tableResult.rows.length} tables:`);
      tableResult.rows.forEach((row) => {
        console.log(`  • ${row.table_name}`);
      });
    } else {
      console.log('⚠️  No tables found');
    }

    await mainClient.end();

    console.log('\n✨ Database setup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error during database setup:', error.message);

    if (error.code === 'ECONNREFUSED') {
      console.error(
        '\n⚠️  Cannot connect to PostgreSQL. Make sure:'
      );
      console.error(
        '  1. PostgreSQL is installed and running'
      );
      console.error(
        '  2. Connection details in .env are correct:'
      );
      console.error(`     DB_HOST: ${process.env.DB_HOST || 'localhost'}`);
      console.error(`     DB_PORT: ${process.env.DB_PORT || 5432}`);
      console.error(`     DB_USER: ${process.env.DB_USER || 'postgres'}`);
    }

    if (error.code === '28P01') {
      console.error(
        '\n⚠️  Authentication failed. Check your DB_PASSWORD in .env'
      );
    }

    process.exit(1);
  }
}

// Run setup
setupDatabase();
