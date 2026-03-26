import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getCategories, getServices } from '../services/api';

const Services = () => {
  const [categories, setCategories] = useState([]);
  const [categoryServices, setCategoryServices] = useState({});
  const [open, setOpen] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      setLoading(true);
      const cats = await getCategories();
      setCategories(cats);

      // Fetch services for each category
      const servicesMap = {};
      await Promise.all(
        cats.map(async (cat) => {
          const id = cat.id || cat._id;
          const services = await getServices(id);
          servicesMap[id] = services;
        })
      );
      setCategoryServices(servicesMap);
    } catch (err) {
      console.error('Failed to load services:', err);
      setError('Unable to load services. Please try again later.');
    } finally {
      setLoading(false);
    }
  }

  // Map category names to fallback images
  function getCategoryImage(name) {
    const lower = (name || '').toLowerCase();
    if (lower.includes('hair') && (lower.includes('cut') || lower.includes('styl'))) return '/images/haircut.jpg';
    if (lower.includes('color')) return '/images/hair coloring.jpg';
    if (lower.includes('treatment')) return '/images/Hair-Treatment.jpg';
    if (lower.includes('facial') || lower.includes('skin')) return '/images/facial.jpg';
    if (lower.includes('makeup') || lower.includes('bridal')) return '/images/makeup.jpeg';
    if (lower.includes('massage') || lower.includes('spa')) return '/images/massage.jpg';
    if (lower.includes('wax')) return '/images/waxing.jpg';
    if (lower.includes('mehndi')) return '/images/mehndi 1.avif';
    if (lower.includes('photo')) return '/images/photoshot.jpg';
    return '/images/salon-interior.jpg';
  }

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
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary" role="status"></div>
              <p className="mt-3 text-muted">Loading services...</p>
            </div>
          ) : error ? (
            <div className="text-center py-5">
              <p className="text-muted">{error}</p>
              <button className="btn btn-gradient mt-2" onClick={loadData}>Retry</button>
            </div>
          ) : (
            <div className="row g-4">
              {categories.map((cat, i) => {
                const catId = cat.id || cat._id;
                const name = cat.name || 'Service';
                const image = cat.image_url || getCategoryImage(name);
                const services = categoryServices[catId] || [];
                const minPrice = services.length
                  ? Math.min(...services.map(s => Number(s.price) || 0))
                  : null;

                return (
                  <div key={catId} className="col-md-4">
                    <div className="card border-0 shadow-sm rounded-4 overflow-hidden service-card-hover" style={{ height: 'auto' }}>
                      <img
                        src={image}
                        className="card-img-top"
                        alt={name}
                        style={{ height: '220px', objectFit: 'cover' }}
                        onError={(e) => { e.target.src = '/images/salon-interior.jpg'; }}
                      />
                      <div className="card-body p-4 text-center d-flex flex-column">
                        <h4 className="card-title fw-bold mb-3">{name}</h4>
                        <p className="card-text text-muted mb-3">
                          Explore our premium {name.toLowerCase()} offerings.
                        </p>

                        {/* Expandable Details */}
                        {open === i && services.length > 0 && (
                          <div
                            className="text-start mb-3 p-3 rounded-3"
                            style={{ background: '#fff0f5', border: '1px solid #ffb3c6' }}
                          >
                            <ul className="list-unstyled mb-2">
                              {services.map((svc) => (
                                <li key={svc.id || svc._id} className="mb-1 d-flex justify-content-between">
                                  <span>
                                    <i className="bi bi-check2-circle text-gradient me-2" />
                                    {svc.name}
                                  </span>
                                  <span className="fw-bold">Rs. {Number(svc.price).toLocaleString()}</span>
                                </li>
                              ))}
                            </ul>
                            {services.length > 0 && (
                              <Link
                                to={`/appointments?type=service&categoryId=${catId}`}
                                className="btn btn-gradient btn-sm w-100 rounded-pill"
                              >
                                Book This Service
                              </Link>
                            )}
                          </div>
                        )}

                        {minPrice !== null && (
                          <p className="fw-bold text-gradient mb-2">Starting from Rs. {minPrice.toLocaleString()}</p>
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
                );
              })}
            </div>
          )}
        </div>
      </section>
    </>
  );
};

export default Services;
