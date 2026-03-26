import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getCourses } from '../services/api';

const Courses = () => {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadCourses();
  }, []);

  async function loadCourses() {
    try {
      setLoading(true);
      setError('');
      const data = await getCourses();
      setCourses(data);
    } catch (err) {
      console.error('Failed to load courses:', err);
      setError('Unable to load courses. Please try again later.');
    } finally {
      setLoading(false);
    }
  }

  const fallbackImages = ['/images/course-1.jpg', '/images/course 2.jpg', '/images/course-3.jpg'];

  return (
    <>
      <section className="courses-hero bg-light py-5">
        <div className="container text-center">
          <h1 className="fw-bold display-4 mb-3">Professional Beauty Courses</h1>
          <p className="lead text-muted">Learn from industry experts and start your career in beauty.</p>
        </div>
      </section>

      <section className="courses-list py-5" style={{ backgroundColor: '#fff9fb' }}>
        <div className="container">
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary" role="status"></div>
              <p className="mt-3 text-muted">Loading courses...</p>
            </div>
          ) : error ? (
            <div className="text-center py-5">
              <p className="text-muted">{error}</p>
              <button className="btn btn-gradient mt-2" onClick={loadCourses}>Retry</button>
            </div>
          ) : courses.length === 0 ? (
            <div className="text-center py-5">
              <p className="text-muted">No courses available at the moment.</p>
            </div>
          ) : (
            <div className="row g-4">
              {courses.map((course, index) => {
                const id = course.id || course._id;
                const title = course.title || 'Course';
                const description = course.description || 'Learn professional beauty skills from certified experts.';
                const duration = course.duration || 'Flexible';
                const price = course.price ? `Rs. ${Number(course.price).toLocaleString()}` : 'Contact for price';
                const image = course.image_url || course.image || fallbackImages[index % fallbackImages.length];

                return (
                  <div key={id} className="col-lg-4 col-md-6">
                    <div className="card h-100 course-card shadow-sm border-0 rounded-4 overflow-hidden position-relative">
                      <div className="card-img-wrapper" style={{ height: '200px', overflow: 'hidden' }}>
                        <img
                          src={image}
                          className="card-img-top w-100 h-100"
                          style={{ objectFit: 'cover' }}
                          alt={title}
                          onError={(e) => { e.target.src = fallbackImages[index % fallbackImages.length]; }}
                        />
                      </div>
                      <div className="card-body p-4 d-flex flex-column">
                        <div className="d-flex justify-content-between align-items-center mb-3">
                          <h4 className="card-title fw-bold mb-0 text-dark">{title}</h4>
                          <span className="badge bg-primary rounded-pill px-3 py-2 fs-6">{duration}</span>
                        </div>
                        <p className="card-text text-muted mb-3">
                          {description.length > 120 ? description.substring(0, 120) + '...' : description}
                        </p>
                        <div className="d-flex justify-content-between align-items-center mt-auto pt-3 border-top">
                          <span className="fs-4 fw-bold text-gradient">{price}</span>
                          <Link
                            to={`/appointments?type=course&courseId=${id}&item=${encodeURIComponent(title)}`}
                            className="btn btn-outline-primary rounded-pill px-4 enroll-btn"
                          >
                            Enroll Now
                          </Link>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </section>
    </>
  );
};

export default Courses;
