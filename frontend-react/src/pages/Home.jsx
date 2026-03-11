import { Link } from 'react-router-dom';
import { useState, useEffect, useRef } from 'react';

// Bootstrap carousel data – images used ONLY here as hero slider
const heroSlides = [
  { img: '/images/haircut.jpg',      caption: 'INCREASE\nBEAUTY'   },
  { img: '/images/waxing.png',       caption: 'FEEL\nCONFIDENT'    },
  { img: '/images/hairironin.png',   caption: 'SHINE\nEVERYDAY'    },
  { img: '/images/hydrafacial.jpg',  caption: 'REFRESH\nYOUR SKIN' },
  { img: '/images/waxing.jpg',       caption: 'LOOK\nGLAMOROUS'    },
];

const testimonials = [
  {
    img:    '/images/background.png',
    quote:  '"The salon experience was amazing. I left feeling refreshed and confident!"',
    name:   'Sarah',
    rating: 5,
  },
  {
    img:    '/images/farhana.jpg',
    quote:  '"They really listen to what I want and always deliver perfectly!"',
    name:   'Farhana',
    rating: 5,
  },
  {
    img:    '/images/shanzay.avif',
    quote:  '"Best salon in town! Excellent service and welcoming atmosphere."',
    name:   'Shanzay',
    rating: 5,
  },
];

const Home = () => {
  const [activeSlide, setActiveSlide] = useState(0);
  const [activeTestimonial, setActiveTestimonial] = useState(0);
  const slideTimer = useRef(null);

  // Auto-advance carousel
  useEffect(() => {
    slideTimer.current = setInterval(() => {
      setActiveSlide(prev => (prev + 1) % heroSlides.length);
    }, 3000);
    return () => clearInterval(slideTimer.current);
  }, []);

  const goToSlide = (idx) => {
    setActiveSlide(idx);
    clearInterval(slideTimer.current);
    slideTimer.current = setInterval(() => {
      setActiveSlide(prev => (prev + 1) % heroSlides.length);
    }, 3000);
  };

  const prevSlide = () => goToSlide((activeSlide - 1 + heroSlides.length) % heroSlides.length);
  const nextSlide = () => goToSlide((activeSlide + 1) % heroSlides.length);

  return (
    <>
      {/* ── Hero Carousel ── */}
      <section className="hero-carousel position-relative" style={{ height: '100vh', overflow: 'hidden' }}>
        {heroSlides.map((slide, i) => (
          <div
            key={i}
            className="carousel-slide"
            style={{
              position: 'absolute', inset: 0,
              transition: 'opacity 0.8s ease',
              opacity: i === activeSlide ? 1 : 0,
              zIndex: i === activeSlide ? 1 : 0,
            }}
          >
            <img
              src={slide.img}
              alt={`Slide ${i + 1}`}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
            {/* Dark overlay */}
            <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.45)' }} />
            {/* Caption */}
            <div
              style={{
                position: 'absolute', inset: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexDirection: 'column', textAlign: 'center',
                color: '#fff',
              }}
            >
              <h1 className="display-1 fw-bold" style={{ letterSpacing: '0.05em', lineHeight: 1.1, whiteSpace: 'pre-line' }}>
                {slide.caption}
              </h1>
              <div className="d-flex gap-3 mt-4">
                <Link to="/appointments" className="btn btn-gradient btn-lg px-5 rounded-pill fw-bold">
                  Book Appointment
                </Link>
                <Link to="/services" className="btn btn-outline-light btn-lg px-5 rounded-pill">
                  View Services
                </Link>
              </div>
            </div>
          </div>
        ))}

        {/* Prev / Next arrows */}
        <button
          onClick={prevSlide}
          className="carousel-ctrl carousel-ctrl-prev"
          aria-label="Previous"
        >
          <i className="bi bi-chevron-left" />
        </button>
        <button
          onClick={nextSlide}
          className="carousel-ctrl carousel-ctrl-next"
          aria-label="Next"
        >
          <i className="bi bi-chevron-right" />
        </button>

        {/* Dot indicators */}
        <div className="carousel-dots">
          {heroSlides.map((_, i) => (
            <button
              key={i}
              onClick={() => goToSlide(i)}
              className={`carousel-dot${i === activeSlide ? ' active' : ''}`}
              aria-label={`Slide ${i + 1}`}
            />
          ))}
        </div>
      </section>

      {/* ── About Preview ── */}
      <section className="about-preview py-5">
        <div className="container overflow-hidden">
          <div className="row align-items-center g-5 py-5">
            <div className="col-lg-6">
              <div className="position-relative">
                <img
                  src="/images/salon-interior.jpg"
                  alt="Salon Interior"
                  className="img-fluid rounded-4 shadow-lg w-100"
                  style={{ objectFit: 'cover', height: '400px' }}
                />
                <div className="experience-badge position-absolute bottom-0 end-0 bg-white p-3 rounded-start shadow">
                  <h3 className="text-gradient fw-bold mb-0">10+</h3>
                  <p className="text-muted mb-0 small">Years Experience</p>
                </div>
              </div>
            </div>
            <div className="col-lg-6">
              <h6 className="text-uppercase text-gradient fw-bold mb-2">Welcome to Merry Queens</h6>
              <h2 className="display-5 fw-bold mb-4">Elevating Beauty, Defy Expectations.</h2>
              <p className="lead text-muted mb-4">
                Our expert stylists and premium products ensure every visit is a refreshing experience tailored uniquely for you.
              </p>
              <ul className="list-unstyled mb-4">
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> Professional &amp; Certified Staff</li>
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> Premium Quality Products</li>
                <li className="mb-2"><i className="bi bi-check-circle-fill text-gradient me-2" /> Relaxing &amp; Luxurious Environment</li>
              </ul>
              <Link to="/about" className="btn btn-outline-dark rounded-pill px-4">
                Read Our Story <i className="bi bi-arrow-right ms-2" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ── Signature Services Preview ── */}
      <section className="services-preview py-5 bg-light">
        <div className="container py-5">
          <div className="text-center mb-5">
            <h6 className="text-uppercase text-gradient fw-bold">What We Offer</h6>
            <h2 className="display-5 fw-bold">Signature Services</h2>
          </div>
          <div className="row g-4">
            {/* Card 1 – Hair Styling: unique image hairservice.jpg */}
            <div className="col-md-4">
              <div className="card h-100 border-0 shadow-sm glass-card text-center p-4">
                <div
                  className="icon-wrapper mb-3 mx-auto"
                  style={{ width: 80, height: 80, borderRadius: '50%', overflow: 'hidden' }}
                >
                  <img src="/images/hairservice.jpg" alt="Hair Styling" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
                <h4 className="fw-bold mb-3">Hair Styling</h4>
                <p className="text-muted mb-4">Expert cuts, vibrant colors, and nourishing treatments for your perfect look.</p>
                <Link to="/services" className="text-gradient fw-bold text-decoration-none mt-auto">
                  Learn More <i className="bi bi-arrow-right" />
                </Link>
              </div>
            </div>
            {/* Card 2 – Bridal Makeup: bride.webp (unique to home) */}
            <div className="col-md-4">
              <div className="card h-100 border-0 shadow-sm glass-card text-center p-4">
                <div
                  className="icon-wrapper mb-3 mx-auto"
                  style={{ width: 80, height: 80, borderRadius: '50%', overflow: 'hidden' }}
                >
                  <img src="/images/EngagementLook.png" alt="Bridal Makeup" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
                <h4 className="fw-bold mb-3">Bridal Makeup</h4>
                <p className="text-muted mb-4">Flawless, long-lasting makeup for your special day using premium brands.</p>
                <Link to="/services" className="text-gradient fw-bold text-decoration-none mt-auto">
                  Learn More <i className="bi bi-arrow-right" />
                </Link>
              </div>
            </div>
            {/* Card 3 – Spa & Relax: massage.webp (unique to home) */}
            <div className="col-md-4">
              <div className="card h-100 border-0 shadow-sm glass-card text-center p-4">
                <div
                  className="icon-wrapper mb-3 mx-auto"
                  style={{ width: 80, height: 80, borderRadius: '50%', overflow: 'hidden' }}
                >
                  <img src="/images/massage.webp" alt="Spa" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                </div>
                <h4 className="fw-bold mb-3">Spa &amp; Relax</h4>
                <p className="text-muted mb-4">Rejuvenating facials, massages, and organic treatments to unwind.</p>
                <Link to="/services" className="text-gradient fw-bold text-decoration-none mt-auto">
                  Learn More <i className="bi bi-arrow-right" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Testimonials ── */}
      <section className="testimonials-section py-5">
        <div className="container text-center py-5">
          <h6 className="text-uppercase text-gradient fw-bold mb-2">Happy Clients</h6>
          <h2 className="display-5 fw-bold mb-5">What Our Clients Say</h2>

          <div className="row justify-content-center">
            <div className="col-lg-8">
              {/* Testimonial Cards */}
              <div style={{ position: 'relative', minHeight: '260px' }}>
                {testimonials.map((t, i) => (
                  <div
                    key={i}
                    style={{
                      position: i === activeTestimonial ? 'relative' : 'absolute',
                      top: 0, left: 0, width: '100%',
                      opacity: i === activeTestimonial ? 1 : 0,
                      transition: 'opacity 0.6s ease',
                      pointerEvents: i === activeTestimonial ? 'auto' : 'none',
                    }}
                  >
                    <div className="card border-0 shadow-sm rounded-4 p-4 p-md-5">
                      <div className="mb-3">
                        {Array.from({ length: t.rating }).map((_, si) => (
                          <i key={si} className="bi bi-star-fill text-warning me-1" />
                        ))}
                      </div>
                      <p className="fs-5 fst-italic text-muted mb-4">{t.quote}</p>
                      <div className="d-flex align-items-center justify-content-center gap-3">
                        <img
                          src={t.img}
                          alt={t.name}
                          style={{ width: 60, height: 60, borderRadius: '50%', objectFit: 'cover', border: '3px solid #FF758C' }}
                        />
                        <div className="text-start">
                          <h6 className="fw-bold mb-0">{t.name}</h6>
                          <small className="text-muted">Merry Queens Client</small>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              {/* Dot navigation */}
              <div className="mt-4 d-flex justify-content-center gap-2">
                {testimonials.map((_, i) => (
                  <button
                    key={i}
                    onClick={() => setActiveTestimonial(i)}
                    style={{
                      width: 12, height: 12, borderRadius: '50%',
                      border: 'none', cursor: 'pointer',
                      background: i === activeTestimonial ? '#FF758C' : '#ddd',
                      transition: 'background 0.3s',
                    }}
                  />
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
};

export default Home;
