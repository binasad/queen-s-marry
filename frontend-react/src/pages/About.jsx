import { Link } from 'react-router-dom';
import { useState } from 'react';

const testimonials = [
  {
    img:  '/images/background.png',
    text: '"The salon experience was amazing. I left feeling refreshed and confident!"',
    name: 'Sarah',
    role: 'Regular Client',
  },
  {
    img:  '/images/farhana.jpg',
    text: '"They really listen to what I want and always deliver perfectly!"',
    name: 'Farhana',
    role: 'Bridal Client',
  },
  {
    img:  '/images/shanzay.avif',
    text: '"Best salon in town! Excellent service and welcoming atmosphere."',
    name: 'Shanzay',
    role: 'Loyal Client',
  },
];

const About = () => {
  const [current, setCurrent] = useState(0);

  return (
    <>
      {/* ── Hero Banner ── */}
      <section
        className="about-hero text-white text-center d-flex align-items-center"
        style={{
          backgroundImage: 'url(/images/about-salon.webp)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          minHeight: '60vh',
          position: 'relative',
        }}
      >
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.55)' }} />
        <div className="container position-relative z-1">
          <h1 className="display-3 fw-bold mb-3">About Us</h1>
          <p className="lead mb-0" style={{ maxWidth: '600px', margin: '0 auto' }}>
            Passionate about beauty. Dedicated to you.
          </p>
        </div>
      </section>

      {/* ── About Content ── */}
      <section className="about-salon py-5 bg-white">
        <div className="container overflow-hidden">
          <div className="row align-items-stretch g-5 py-5">
            <div className="col-lg-5">
              <div className="position-relative h-100">
                <img
                  src="/images/photoshot.jpg"
                  alt="Our Salon"
                  className="img-fluid rounded-4 shadow-lg w-100 h-100"
                  style={{ objectFit: 'cover', minHeight: '500px' }}
                />
                <div className="experience-badge position-absolute bottom-0 end-0 bg-white p-3 rounded-start shadow">
                  <h3 className="text-gradient fw-bold mb-0">10+</h3>
                  <p className="text-muted mb-0 small">Years Experience</p>
                </div>
              </div>
            </div>
            <div className="col-lg-7 d-flex flex-column justify-content-center">
              <h6 className="text-uppercase text-gradient fw-bold mb-2">Our Story</h6>
              <h2 className="display-5 fw-bold mb-4">About Merry Queens Salon</h2>
              <p className="lead text-muted mb-4">
                At <strong>Merry Queens Salon</strong>, we believe beauty is more than looks —
                it's confidence. Our expert stylists, warm ambiance, and top-quality products
                ensure every visit is a refreshing experience. Whether it's a simple trim,
                a bold makeover, or a relaxing spa treatment, we're here to make you shine.
              </p>
              <ul className="list-unstyled mb-4">
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> Professional &amp; Certified Stylists</li>
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> Premium Quality Products Only</li>
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> Relaxing &amp; Luxurious Environment</li>
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> 10+ Years of Trusted Service</li>
              </ul>
              <Link to="/services" className="btn btn-gradient px-4 py-2 rounded-pill">
                Explore Our Services <i className="bi bi-arrow-right ms-2" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ── Testimonials ── */}
      <section className="py-5" style={{ background: 'linear-gradient(135deg,#fff0f5,#f5f0ff)' }}>
        <div className="container text-center py-3">
          <h6 className="text-uppercase text-gradient fw-bold mb-2">Happy Clients</h6>
          <h2 className="fw-bold mb-5">What Our Clients Say</h2>

          {/* Single active testimonial card */}
          <div className="row justify-content-center">
            <div className="col-lg-7 col-md-10">
              <div className="card border-0 shadow rounded-4 p-4 p-md-5">
                <img
                  src={testimonials[current].img}
                  alt={testimonials[current].name}
                  style={{
                    width: 90, height: 90, borderRadius: '50%',
                    objectFit: 'cover', border: '4px solid #FF758C',
                    margin: '0 auto 1rem',
                    display: 'block',
                  }}
                />
                <div className="mb-3">
                  {[...Array(5)].map((_, i) => (
                    <i key={i} className="bi bi-star-fill text-warning me-1" />
                  ))}
                </div>
                <p className="fs-5 fst-italic text-muted mb-4">{testimonials[current].text}</p>
                <h5 className="fw-bold text-gradient mb-0">{testimonials[current].name}</h5>
                <small className="text-muted">{testimonials[current].role}</small>
              </div>

              {/* Prev / Next + Dot nav */}
              <div className="d-flex align-items-center justify-content-center gap-3 mt-4">
                <button
                  className="btn btn-outline-secondary rounded-circle p-0 d-flex align-items-center justify-content-center"
                  style={{ width: 40, height: 40 }}
                  onClick={() => setCurrent((current - 1 + testimonials.length) % testimonials.length)}
                  aria-label="Previous"
                >
                  <i className="bi bi-chevron-left" />
                </button>

                {testimonials.map((_, i) => (
                  <button
                    key={i}
                    onClick={() => setCurrent(i)}
                    style={{
                      width: 12, height: 12, borderRadius: '50%',
                      border: 'none', padding: 0, cursor: 'pointer',
                      background: i === current ? '#FF758C' : '#ddd',
                      transition: 'background 0.3s',
                    }}
                    aria-label={`Go to testimonial ${i + 1}`}
                  />
                ))}

                <button
                  className="btn btn-outline-secondary rounded-circle p-0 d-flex align-items-center justify-content-center"
                  style={{ width: 40, height: 40 }}
                  onClick={() => setCurrent((current + 1) % testimonials.length)}
                  aria-label="Next"
                >
                  <i className="bi bi-chevron-right" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Map ── */}
      <section className="map-section py-5 bg-white">
        <div className="container text-center">
          <h2 className="mb-4 fw-bold">Find Us Here</h2>
          <div className="ratio ratio-21x9 shadow-sm" style={{ borderRadius: '15px', overflow: 'hidden' }}>
            <iframe
              src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3321.308894892646!2d73.06990461520111!3d33.64936308071853!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x38df95217469aaff%3A0xe5a20af9ceb2e6aa!2sI-8%20Markaz%20Islamabad%2C%20Islamabad%20Capital%20Territory%2C%20Pakistan!5e0!3m2!1sen!2s!4v1690000000000!5m2!1sen!2s"
              style={{ border: 0 }}
              allowFullScreen=""
              loading="lazy"
              referrerPolicy="no-referrer-when-downgrade"
              title="Merry Queens Salon Location"
            />
          </div>
        </div>
      </section>
    </>
  );
};

export default About;
