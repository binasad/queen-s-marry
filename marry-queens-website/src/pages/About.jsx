import { Link } from 'react-router-dom';

const testimonials = [
  {
    img: '/images/background.png',
    text: '"The attention to detail at Queen\'s Merry is unmatched. My bridal makeup was exactly what I dreamed of — sophisticated and radiant."',
    name: 'Sarah',
    role: 'Regular Client',
  },
  {
    img: '/images/farhana.jpg',
    text: '"They really listen to what I want and always deliver perfectly! The most relaxing experience I\'ve ever had."',
    name: 'Farhana',
    role: 'Bridal Client',
  },
  {
    img: '/images/shanzay.avif',
    text: '"Best saloon in town! Their hair coloring experts are magical. Excellent service and welcoming atmosphere."',
    name: 'Shanzay',
    role: 'Loyal Client',
  },
];

const About = () => {
  return (
    <>
      {/* ── Hero Banner ── */}
      <section
        className="text-white text-center d-flex align-items-center justify-content-center"
        style={{
          backgroundImage: 'url(/images/about-salon.webp)',
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          minHeight: '60vh',
          position: 'relative',
        }}
      >
        {/* gradient fade bottom so it blends into the next white section */}
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, rgba(0,0,0,0.55) 60%, rgba(255,255,255,0.05) 100%)' }} />
        <div className="container position-relative" style={{ zIndex: 1 }}>
          <span
            className="d-inline-block fw-bold text-uppercase mb-3"
            style={{ color: '#FF80A5', letterSpacing: '0.18em', fontSize: '0.85rem' }}
          >
            The Art of Transformation
          </span>
          <h1 className="display-3 fw-bold mb-3">About Us</h1>
          <p className="lead mb-0" style={{ maxWidth: '600px', margin: '0 auto', color: 'rgba(255,255,255,0.85)' }}>
            Where royal treatment meets modern expertise in the heart of Islamabad.
          </p>
        </div>
      </section>

      {/* ── Story / About Section ── */}
      <section className="py-5 py-lg-6 bg-white">
        <div className="container py-3">
          <div className="row g-5 align-items-center">

            {/* Image with decorative block behind it */}
            <div className="col-lg-6 position-relative">
              {/* Decorative pink block */}
              <div
                style={{
                  position: 'absolute',
                  top: -20,
                  left: -20,
                  width: 220,
                  height: 220,
                  background: '#ffd0e5',
                  borderRadius: '1rem',
                  zIndex: 0,
                }}
              />
              <img
                src="/images/photoshot.jpg"
                alt="Our Saloon"
                className="img-fluid rounded-4 shadow-lg w-100 position-relative"
                style={{
                  objectFit: 'cover',
                  aspectRatio: '4/5',
                  maxHeight: '560px',
                  zIndex: 1,
                }}
              />
              {/* Soft blur orb bottom-right */}
              <div
                style={{
                  position: 'absolute',
                  bottom: -30,
                  right: -30,
                  width: 160,
                  height: 160,
                  background: 'rgba(196,113,237,0.18)',
                  borderRadius: '50%',
                  filter: 'blur(40px)',
                  zIndex: 0,
                  display: 'none',
                }}
                className="d-lg-block"
              />
            </div>

            {/* Text Side */}
            <div className="col-lg-6">
              <span
                className="d-block fw-bold text-uppercase mb-3"
                style={{ color: '#9f3458', letterSpacing: '0.2em', fontSize: '0.8rem' }}
              >
                Our Legacy
              </span>
              <h2 className="fw-bold mb-4" style={{ fontSize: '2.6rem', lineHeight: 1.15 }}>
                About Our Saloon
              </h2>
              <p className="text-muted mb-3" style={{ fontSize: '1.05rem', lineHeight: 1.8 }}>
                Founded on the principle that every individual deserves a moment of pure royalty,{' '}
                <strong>Queen's Merry Beauty Saloon</strong> has become Islamabad's premier destination for
                luxury grooming and bridal expertise.
              </p>
              <p className="text-muted mb-5" style={{ fontSize: '1.05rem', lineHeight: 1.8 }}>
                Our mission is simple: to blend traditional hospitality with cutting-edge beauty techniques. From
                high-fashion hair styling to meditative skincare rituals, we provide a sanctuary where your inner
                radiance is brought to life by our master technicians.
              </p>
              <div className="d-flex flex-wrap gap-3">
                <Link
                  to="/services"
                  className="btn btn-gradient btn-lg px-5 py-3 rounded-pill shadow d-flex align-items-center gap-2"
                >
                  Explore Our Services <i className="bi bi-arrow-right" />
                </Link>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* ── Testimonials — 3-column cards ── */}
      <section
        className="py-5 py-lg-6"
        style={{ background: '#fff4f6', borderRadius: '2.5rem 2.5rem 0 0' }}
      >
        <div className="container py-3">
          <div className="text-center mb-5">
            <h2 className="fw-bold mb-2" style={{ fontSize: '2.4rem' }}>Our Customer Reviews</h2>
            <p className="text-muted">Real experiences from our valued clients</p>
          </div>

          <div className="row g-4 align-items-start">
            {testimonials.map((t, i) => (
              <div
                key={i}
                className="col-md-4"
                style={{ marginTop: i === 1 ? '2rem' : 0 }}
              >
                <div
                  className="h-100 p-4 rounded-4 d-flex flex-column justify-content-between"
                  style={{
                    background: '#fff',
                    boxShadow: '0 24px 48px -12px rgba(73,33,55,0.08)',
                  }}
                >
                  {/* Stars */}
                  <div>
                    <div className="mb-3">
                      {[...Array(5)].map((_, j) => (
                        <i key={j} className="bi bi-star-fill me-1" style={{ color: '#9f3458' }} />
                      ))}
                    </div>
                    {/* Quote */}
                    <p className="fst-italic text-muted mb-0" style={{ lineHeight: 1.75, fontSize: '0.97rem' }}>
                      {t.text}
                    </p>
                  </div>

                  {/* Avatar + name */}
                  <div className="d-flex align-items-center gap-3 mt-4 pt-3" style={{ borderTop: '1px solid #f5e0eb' }}>
                    <img
                      src={t.img}
                      alt={t.name}
                      style={{
                        width: 48,
                        height: 48,
                        borderRadius: '50%',
                        objectFit: 'cover',
                        border: '2px solid #FF80A5',
                        flexShrink: 0,
                      }}
                    />
                    <div>
                      <p className="fw-bold mb-0" style={{ color: '#1a1a1a' }}>{t.name}</p>
                      <small className="text-muted">{t.role}</small>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Find Us — split card with working map ── */}
      <section className="py-5 py-lg-6 bg-white">
        <div className="container">
          <div
            className="overflow-hidden rounded-4"
            style={{
              background: '#ffd0e5',
              boxShadow: '0 24px 48px -12px rgba(73,33,55,0.08)',
            }}
          >
            <div className="row g-0" style={{ minHeight: 420 }}>

              {/* Left — info */}
              <div className="col-lg-5 p-5 d-flex flex-column justify-content-center">
                <h2 className="fw-bold mb-2" style={{ fontSize: '2rem' }}>Find Us</h2>
                <p className="text-muted mb-4">Visit our sanctuary in the heart of the capital.</p>

                <div className="d-flex align-items-start gap-3 mb-4">
                  <div
                    className="d-flex align-items-center justify-content-center rounded-circle flex-shrink-0"
                    style={{ width: 48, height: 48, background: 'rgba(159,52,88,0.1)' }}
                  >
                    <i className="bi bi-geo-alt-fill" style={{ color: '#9f3458', fontSize: '1.2rem' }} />
                  </div>
                  <div>
                    <p className="fw-bold mb-0" style={{ color: '#1a1a1a' }}>Address</p>
                    <p className="text-muted mb-0">Plot #14, I-8 Markaz, Islamabad, Pakistan</p>
                  </div>
                </div>

                <div className="d-flex align-items-start gap-3 mb-4">
                  <div
                    className="d-flex align-items-center justify-content-center rounded-circle flex-shrink-0"
                    style={{ width: 48, height: 48, background: 'rgba(159,52,88,0.1)' }}
                  >
                    <i className="bi bi-telephone-fill" style={{ color: '#9f3458', fontSize: '1.1rem' }} />
                  </div>
                  <div>
                    <p className="fw-bold mb-0" style={{ color: '#1a1a1a' }}>Contact</p>
                    <p className="text-muted mb-0">+92-308-5494369</p>
                    <p className="text-muted mb-0">info@marryqueens.com</p>
                  </div>
                </div>

                <div className="d-flex align-items-start gap-3">
                  <div
                    className="d-flex align-items-center justify-content-center rounded-circle flex-shrink-0"
                    style={{ width: 48, height: 48, background: 'rgba(159,52,88,0.1)' }}
                  >
                    <i className="bi bi-clock-fill" style={{ color: '#9f3458', fontSize: '1.1rem' }} />
                  </div>
                  <div>
                    <p className="fw-bold mb-0" style={{ color: '#1a1a1a' }}>Working Hours</p>
                    <p className="text-muted mb-0">Mon – Sun: 10:00 AM – 09:00 PM</p>
                  </div>
                </div>
              </div>

              {/* Right — Google Maps iframe (working, not static) */}
              <div className="col-lg-7" style={{ minHeight: 380 }}>
                <iframe
                  src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3321.308894892646!2d73.06990461520111!3d33.64936308071853!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x38df95217469aaff%3A0xe5a20af9ceb2e6aa!2sI-8%20Markaz%20Islamabad%2C%20Islamabad%20Capital%20Territory%2C%20Pakistan!5e0!3m2!1sen!2s!4v1690000000000!5m2!1sen!2s"
                  style={{ border: 0, width: '100%', height: '100%', minHeight: 380 }}
                  allowFullScreen=""
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                  title="Queen's Merry Saloon Location"
                />
              </div>

            </div>
          </div>
        </div>
      </section>
    </>
  );
};

export default About;
