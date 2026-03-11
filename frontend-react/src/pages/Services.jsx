import { useState } from 'react';
import { Link } from 'react-router-dom';

const services = [
  {
    img:   '/images/hair coloring.jpg',
    title: 'Hair Styling & Coloring',
    desc:  'Transform your look with expert cuts, blowouts, and vibrant, damage-free color treatments.',
    details: [
      'Haircut & Blowdry',
      'Hair Coloring (Full / Partial)',
      'Highlights & Balayage',
      'Keratin Smoothing Treatment',
      'Deep Conditioning Mask',
    ],
    price: 'Starting from Rs. 1,500',
    link:  '/appointments?service=hair',
  },
  {
    img:   '/images/facial.jpg',
    title: 'Skin Care & Facials',
    desc:  'Rejuvenate your skin with our deep-cleansing organic facials and anti-aging therapies.',
    details: [
      'Classic Deep Cleansing Facial',
      'Whitening & Brightening Facial',
      'Anti-Aging / Gold Facial',
      'Hydra Facial',
      'Eyebrow Threading & Shaping',
    ],
    price: 'Starting from Rs. 2,000',
    link:  '/appointments?service=facial',
  },
  {
    img:   '/images/makeup.jpeg',
    title: 'Bridal & Party Makeup',
    desc:  'Look flawless on your big day. We use premium brands for a long-lasting, stunning finish.',
    details: [
      'HD Bridal Makeup',
      'Engagement / Party Makeup',
      'Airbrush Makeup',
      'Mehndi Look Makeup',
      'Saree & Formal Draping',
    ],
    price: 'Starting from Rs. 5,000',
    link:  '/appointments?service=makeup',
  },
];

const Services = () => {
  const [open, setOpen] = useState(null);

  return (
    <>
      {/* Hero */}
      <section className="hero-services text-center text-white py-5">
        <div className="container my-5">
          <h1 className="fw-bold display-4">Our Services</h1>
          <p className="lead">Luxury treatments designed to bring out your inner queen.</p>
        </div>
      </section>

      {/* Service Cards */}
      <section className="py-5" style={{ backgroundColor: '#fff0f5' }}>
        <div className="container">
          <div className="row g-4">
            {services.map((s, i) => (
              <div key={i} className="col-md-4">
                <div className="card border-0 shadow-sm rounded-4 overflow-hidden service-card-hover" style={{ height: 'auto' }}>
                  <img
                    src={s.img}
                    className="card-img-top"
                    alt={s.title}
                    style={{ height: '220px', objectFit: 'cover' }}
                  />
                  <div className="card-body p-4 text-center d-flex flex-column">
                    <h4 className="card-title fw-bold mb-3">{s.title}</h4>
                    <p className="card-text text-muted mb-3">{s.desc}</p>

                    {/* Expandable Details */}
                    {open === i && (
                      <div
                        className="text-start mb-3 p-3 rounded-3"
                        style={{ background: '#fff0f5', border: '1px solid #ffb3c6' }}
                      >
                        <ul className="list-unstyled mb-2">
                          {s.details.map((d, di) => (
                            <li key={di} className="mb-1">
                              <i className="bi bi-check2-circle text-gradient me-2" />
                              {d}
                            </li>
                          ))}
                        </ul>
                        <p className="fw-bold text-gradient mb-2">{s.price}</p>
                        <Link to={s.link} className="btn btn-gradient btn-sm w-100 rounded-pill">
                          Book This Service
                        </Link>
                      </div>
                    )}

                    <button
                      className="btn btn-outline-dark rounded-pill px-4 mt-auto"
                      onClick={() => setOpen(open === i ? null : i)}
                    >
                      {open === i ? 'Hide Details' : 'View Details'}
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </>
  );
};

export default Services;
