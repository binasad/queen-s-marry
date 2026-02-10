/* eslint-disable no-console */
/**
 * Seed service categories + services from the Flutter app hardcoded lists.
 *
 * Why: admin-web `/services` reads from DB via backend APIs. If DB is empty,
 * the UI will be empty. This script migrates the salon-app hardcoded services
 * into the database (no "import page" needed).
 *
 * Run:
 *   npm run seed:services
 */
const fs = require('fs');
const path = require('path');
const { query, pool } = require('../config/db');

// Base URL for S3-hosted assets (adjust region/key prefix if needed)
const S3_BASE_URL = 'https://salon-app-assets-saad.s3.amazonaws.com/';

function parseDurationToMinutes(durationStr) {
  if (!durationStr) return 60;
  const s = String(durationStr).trim();

  // "Varies (2–3 hrs per event)" => use inner range / first number
  const inner = s.match(/\(([^)]+)\)/);
  const base = inner ? inner[1] : s;

  // Range: "60–90 mins" or "60-90 mins" => average
  const range = base.match(/(\d+)\s*[–-]\s*(\d+)/);
  if (range) {
    const a = parseInt(range[1], 10);
    const b = parseInt(range[2], 10);
    // Decide units by presence of hrs
    if (/hrs?/i.test(base)) return Math.round(((a + b) / 2) * 60);
    return Math.round((a + b) / 2);
  }

  // Hours: "2 hrs", "3 hr"
  const hrs = base.match(/(\d+)\s*hrs?/i);
  if (hrs) return parseInt(hrs[1], 10) * 60;

  // Minutes: "45 mins", "5 min"
  const mins = base.match(/(\d+)\s*mins?/i);
  if (mins) return parseInt(mins[1], 10);

  // Fallback: extract first number and assume minutes
  const num = base.match(/(\d+)/);
  if (num) return parseInt(num[1], 10);

  return 60;
}

function extractFirstListLiteral(content) {
  const startIdx = content.indexOf('List<Map<String, dynamic>>');
  if (startIdx === -1) return null;

  const bracketStart = content.indexOf('[', startIdx);
  if (bracketStart === -1) return null;

  let depth = 0;
  for (let i = bracketStart; i < content.length; i++) {
    const ch = content[i];
    if (ch === '[') depth++;
    else if (ch === ']') depth--;
    if (depth === 0) {
      return content.slice(bracketStart, i + 1);
    }
  }
  return null;
}

function extractMapBlocks(listLiteral) {
  const maps = [];
  let depth = 0;
  let start = -1;
  for (let i = 0; i < listLiteral.length; i++) {
    const ch = listLiteral[i];
    if (ch === '{') {
      if (depth === 0) start = i;
      depth++;
    } else if (ch === '}') {
      depth--;
      if (depth === 0 && start !== -1) {
        maps.push(listLiteral.slice(start, i + 1));
        start = -1;
      }
    }
  }
  return maps;
}

function getDartString(mapStr, key) {
  // Handles:
  // 'description': 'text...'
  // 'description':
  //    'text...'
  const re = new RegExp(`'${key}'\\s*:\\s*'([^']*)'`, 'm');
  const m = mapStr.match(re);
  return m ? m[1].trim() : null;
}

function getDartNumber(mapStr, key) {
  const re = new RegExp(`'${key}'\\s*:\\s*(\\d+)`, 'm');
  const m = mapStr.match(re);
  return m ? parseInt(m[1], 10) : null;
}

function parseServicesFromDartFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const list = extractFirstListLiteral(content);
  if (!list) {
    throw new Error(`Could not find List<Map<String, dynamic>> in ${filePath}`);
  }
  const blocks = extractMapBlocks(list);
  return blocks
    .map((b) => {
      const name = getDartString(b, 'name');
      const description = getDartString(b, 'description') || '';
      const duration = getDartString(b, 'duration') || '';
      const image = getDartString(b, 'image');
      const price = getDartNumber(b, 'price');
      if (!name || !price) return null;
      return { name, description, duration, image, price };
    })
    .filter(Boolean);
}

async function ensureCategory({ name, description, displayOrder, imageKey }) {
  const existing = await query(
    'SELECT id, image_url FROM service_categories WHERE LOWER(name) = LOWER($1) LIMIT 1',
    [name]
  );

  const imageUrl = imageKey ? `${S3_BASE_URL}${imageKey}` : null;

  if (existing.rows.length > 0) {
    const id = existing.rows[0].id;
    // If category exists but has no image_url yet, set it
    if (imageUrl && !existing.rows[0].image_url) {
      await query(
        'UPDATE service_categories SET image_url = $1 WHERE id = $2',
        [imageUrl, id]
      );
    }
    return id;
  }

  const created = await query(
    `INSERT INTO service_categories (name, description, display_order, is_active, image_url)
     VALUES ($1, $2, $3, TRUE, $4)
     RETURNING id`,
    [name, description || null, displayOrder || 0, imageUrl]
  );
  return created.rows[0].id;
}

async function ensureService({ categoryId, name, description, price, durationMinutes, tags, imageKey }) {
  const existing = await query(
    'SELECT id, image_url FROM services WHERE LOWER(name) = LOWER($1) AND category_id = $2 LIMIT 1',
    [name, categoryId]
  );

  const imageUrl = imageKey ? `${S3_BASE_URL}${imageKey}` : null;

  if (existing.rows.length > 0) {
    const id = existing.rows[0].id;
    // If service exists but has no image_url, set it
    if (imageUrl && !existing.rows[0].image_url) {
      await query(
        'UPDATE services SET image_url = $1 WHERE id = $2',
        [imageUrl, id]
      );
    }
    return { id, created: false };
  }

  const created = await query(
    `INSERT INTO services (category_id, name, description, price, duration, image_url, tags, is_active)
     VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
     RETURNING id`,
    [categoryId, name, description || null, price, durationMinutes, imageUrl, tags || []]
  );
  return { id: created.rows[0].id, created: true };
}

async function main() {
  const root = path.resolve(__dirname, '../../..'); // d:/Aztrosys
  const servicesDir = path.resolve(root, 'salon-app/lib/AppScreens/Services');

  const sources = [
    {
      category: 'Hair Services',
      categoryDescription: 'Hair cutting, coloring and treatment services',
      displayOrder: 1,
      categoryImageKey: 'assets/FeatherCutting.png',
      tag: 'Hair Cutting',
      file: path.resolve(servicesDir, 'HairCutting.dart'),
    },
    {
      category: 'Hair Services',
      categoryDescription: 'Hair cutting, coloring and treatment services',
      displayOrder: 1,
      categoryImageKey: 'assets/FeatherCutting.png',
      tag: 'Hair Color',
      file: path.resolve(servicesDir, 'HairColoring.dart'),
    },
    {
      category: 'Hair Services',
      categoryDescription: 'Hair cutting, coloring and treatment services',
      displayOrder: 1,
      categoryImageKey: 'assets/FeatherCutting.png',
      tag: 'Hair Treatment',
      file: path.resolve(servicesDir, 'HairTreatment.dart'),
    },
    {
      category: 'Makeup Services',
      categoryDescription: 'Makeup services',
      displayOrder: 2,
      categoryImageKey: 'assets/MakeUp.jpg',
      tag: null,
      file: path.resolve(servicesDir, 'UserMakeupServices.dart'),
    },
    {
      category: 'Facial Services',
      categoryDescription: 'Facial services and treatments',
      displayOrder: 3,
      categoryImageKey: 'assets/FruitFacial.jpg',
      tag: 'Facial',
      file: path.resolve(servicesDir, 'FacialService.dart'),
    },
    {
      category: 'Facial Services',
      categoryDescription: 'Facial services and treatments',
      displayOrder: 3,
      categoryImageKey: 'assets/FruitFacial.jpg',
      tag: 'Treatment',
      file: path.resolve(servicesDir, 'FacialTreatment.dart'),
    },
    {
      category: 'Massage Services',
      categoryDescription: 'Massage services',
      displayOrder: 4,
      categoryImageKey: 'assets/DeepTissueMassage.jpg',
      tag: null,
      file: path.resolve(servicesDir, 'UserMassageServices.dart'),
    },
    {
      category: 'Mehndi Services',
      categoryDescription: 'Mehndi services',
      displayOrder: 5,
      categoryImageKey: 'assets/Mehndi.jpg',
      tag: null,
      file: path.resolve(servicesDir, 'UserMehndiServices.dart'),
    },
    {
      category: 'Waxing Services',
      categoryDescription: 'Waxing services',
      displayOrder: 6,
      categoryImageKey: 'assets/Waxing.jpg',
      tag: null,
      file: path.resolve(servicesDir, 'UserWaxingServices.dart'),
    },
    {
      category: 'PhotoShoot Services',
      categoryDescription: 'Photoshoot services',
      displayOrder: 7,
      categoryImageKey: 'assets/PhotoShoot.jpg',
      tag: null,
      file: path.resolve(servicesDir, 'PhotoShootServices.dart'),
    },
  ];

  console.log('Seeding categories + services from salon-app...');
  console.log('Root:', root);
  console.log('Services dir:', servicesDir);

  // Pre-create categories (consistent IDs reused across multiple sources)
  const categoryIds = new Map();
  for (const src of sources) {
    if (categoryIds.has(src.category)) continue;
    const id = await ensureCategory({
      name: src.category,
      description: src.categoryDescription,
      displayOrder: src.displayOrder,
      imageKey: src.categoryImageKey,
    });
    categoryIds.set(src.category, id);
  }

  let createdServices = 0;
  let skippedServices = 0;
  let parsedTotal = 0;

  for (const src of sources) {
    const categoryId = categoryIds.get(src.category);
    if (!categoryId) throw new Error(`Missing category id for ${src.category}`);

    const parsed = parseServicesFromDartFile(src.file);
    parsedTotal += parsed.length;

    for (const item of parsed) {
      const durationMinutes = parseDurationToMinutes(item.duration);
      const tags = [];
      if (src.tag) tags.push(src.tag);
      const result = await ensureService({
        categoryId,
        name: item.name,
        description: item.description,
        price: item.price,
        durationMinutes,
        tags,
        imageKey: item.image, // use same relative key as in assets folder
      });
      if (result.created) createdServices++;
      else skippedServices++;
    }
  }

  console.log('\n✅ Seed complete');
  console.log('Categories:', categoryIds.size);
  console.log('Services parsed:', parsedTotal);
  console.log('Services created:', createdServices);
  console.log('Services skipped (already existed):', skippedServices);
}

main()
  .catch((err) => {
    console.error('\n❌ Seed failed:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    try {
      await pool.end();
    } catch (e) {
      // ignore
    }
  });

