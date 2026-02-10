/* eslint-disable no-console */
/**
 * Seed courses from the Flutter app hardcoded list.
 *
 * Why: admin-web `/courses` reads from DB via backend APIs. If DB is empty,
 * the UI will be empty. This script migrates the salon-app hardcoded courses
 * into the database.
 *
 * Run:
 *   npm run seed:courses
 */
const { query, pool } = require('../config/db');

// Base URL for S3-hosted assets (adjust if needed)
const S3_BASE_URL = 'https://salon-app-assets-saad.s3.amazonaws.com/';

// Hardcoded courses from salon-app/lib/AppScreens/UserScreens/Course Screens/CoursesScreen.dart
const HARDCODED_COURSES = [
  {
    title: 'Basic Level',
    description: `The Basic Level course is designed for beginners who want to start their journey in the beauty and wellness industry. 
In this 3-month program, you will learn essential skills in Hair styling, Mehndi application, and basic Massage techniques. 

Key Highlights:
• Hands-on practical sessions to master foundational skills.
• Introduction to hygiene, safety, and client care.
• Step-by-step guidance from experienced beauticians.
• Opportunity to build confidence before moving to advanced courses.
Upon completion, you will receive a certificate validating your skills in these basic beauty treatments.`,
    duration: '3 Month',
    price: 75000.00,
    imageUrl: `${S3_BASE_URL}assets/BasicCourse.png`,
    subjects: ['Hair', 'Mehndi', 'Massage'],
  },
  {
    title: 'Advance Level',
    description: `The Advance Level course is perfect for students who have basic knowledge and want to enhance their expertise. 
This 6-month program covers advanced Hair techniques, professional Makeup, Waxing, Facial treatments, and Massage. 

Key Highlights:
• Detailed theory and practical sessions for advanced techniques.
• Learn to handle diverse client requirements and preferences.
• Tips on managing a small beauty business or freelancing.
• Training on professional-grade tools and products.
By the end of this course, students will gain practical experience and a certificate that showcases their proficiency in multiple beauty treatments.`,
    duration: '6 Months',
    price: 120000.00,
    imageUrl: `${S3_BASE_URL}assets/AdvanceCourse.png`,
    subjects: ['Hair', 'Mehndi', 'Makeup', 'Waxing', 'Facial', 'Massage'],
  },
  {
    title: 'Professional Level',
    description: `The Pro Level course is designed for ambitious individuals aiming to become professional beauty experts. 
This 12-month comprehensive program covers every aspect of Hair, Mehndi, Makeup, Waxing, Facial, and Massage treatments. 

Key Highlights:
• Advanced techniques for all subjects, including high-end beauty treatments.
• Client management, consultation skills, and personalized service training.
• Hands-on experience with professional equipment and products.
• Guidance on starting your own salon or becoming a freelance beauty consultant.
Upon successful completion, students will receive a Pro-level certificate, preparing them for a rewarding career in the beauty industry.`,
    duration: '12 Months',
    price: 180000.00,
    imageUrl: `${S3_BASE_URL}assets/ProCourse.png`,
    subjects: ['Hair', 'Mehndi', 'Makeup', 'Waxing', 'Facial', 'Massage'],
  },
];

async function ensureCourse({ title, description, duration, price, imageUrl, subjects }) {
  // Check if course already exists
  const existing = await query(
    'SELECT id, image_url FROM courses WHERE LOWER(title) = LOWER($1) LIMIT 1',
    [title]
  );

  // If subjects are provided, append them to description
  let fullDescription = description;
  if (subjects && subjects.length > 0) {
    const subjectsText = `\n\nSubjects Included: ${subjects.join(', ')}`;
    fullDescription = description + subjectsText;
  }

  if (existing.rows.length > 0) {
    const id = existing.rows[0].id;
    // If course exists but has no image_url, update it
    if (imageUrl && !existing.rows[0].image_url) {
      await query(
        'UPDATE courses SET image_url = $1, description = $2 WHERE id = $3',
        [imageUrl, fullDescription, id]
      );
      console.log(`  ✓ Updated image_url for: ${title}`);
    }
    return { id, created: false };
  }

  // Create new course
  const result = await query(
    `INSERT INTO courses (title, description, duration, price, image_url, is_active)
     VALUES ($1, $2, $3, $4, $5, TRUE)
     RETURNING id`,
    [title, fullDescription, duration, price, imageUrl]
  );
  return { id: result.rows[0].id, created: true };
}

async function main() {
  console.log('🌱 Seeding courses from salon-app hardcoded data...\n');

  let createdCourses = 0;
  let skippedCourses = 0;

  for (const course of HARDCODED_COURSES) {
    const result = await ensureCourse(course);
    if (result.created) {
      createdCourses++;
      console.log(`  ✓ Created: ${course.title}`);
    } else {
      skippedCourses++;
      console.log(`  ⊘ Skipped (already exists): ${course.title}`);
    }
  }

  console.log('\n✅ Seed complete!');
  console.log(`   Created: ${createdCourses} courses`);
  console.log(`   Skipped: ${skippedCourses} courses (already existed)`);
}

main()
  .then(() => {
    console.log('\n✨ Done!');
    process.exit(0);
  })
  .catch((err) => {
    console.error('\n❌ Seed failed:', err);
    process.exit(1);
  })
  .finally(() => {
    pool.end();
  });
