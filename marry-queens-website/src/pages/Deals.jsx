import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getOffers } from '../services/api';

const Deals = () => {
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadOffers();
  }, []);

  async function loadOffers() {
    try {
      setLoading(true);
      setError('');
      const data = await getOffers();
      setOffers(data);
    } catch (err) {
      console.error('Failed to load offers:', err);
      setError('Unable to load offers. Please try again later.');
    } finally {
      setLoading(false);
    }
  }

  const fallbackImages = ['/images/bride.webp', '/images/makeup.jpeg', '/images/haircut.jpg'];
  const colorSchemes = [
    { header: 'bg-danger', badge: 'bg-white text-danger', btn: 'btn-danger', icon: 'text-success' },
    { header: '', headerStyle: { background: 'linear-gradient(135deg, #FF758C 0%, #9D50BB 100%)' }, badge: 'bg-white text-primary', btn: 'btn-primary btn-gradient', icon: 'text-primary' },
    { header: 'bg-dark', badge: 'bg-light text-dark', btn: 'btn-dark', icon: 'text-dark' },
  ];

  function getDaysLeft(endDate) {
    if (!endDate) return null;
    const end = new Date(endDate);
    const now = new Date();
    const days = Math.ceil((end - now) / (1000 * 60 * 60 * 24));
    if (days < 0) return 'Expired';
    if (days === 0) return 'Ends today!';
    return `${days} days left`;
  }

  return (
    <>
      <section className="deals-hero py-5 text-white" style={{ background: 'linear-gradient(135deg, #1a1a2e, #16213e)', position: 'relative', overflow: 'hidden' }}>
        <div className="container text-center py-4 position-relative z-1">
          <h1 className="display-4 fw-bold mb-3"><i className="bi bi-tags-fill me-3 text-warning"></i>Exclusive Offers</h1>
          <p className="lead fw-light">Hurry up! Grab our limited-time beauty combos at unbeatable prices.</p>
        </div>
        <div className="position-absolute top-0 start-0 w-100 h-100" style={{ background: 'linear-gradient(rgba(0,0,0,0.2), rgba(0,0,0,0.2))' }}></div>
      </section>

      <section className="deals-list py-5 bg-light">
        <div className="container">
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary" role="status"></div>
              <p className="mt-3 text-muted">Loading offers...</p>
            </div>
          ) : error ? (
            <div className="text-center py-5">
              <p className="text-muted">{error}</p>
              <button className="btn btn-gradient mt-2" onClick={loadOffers}>Retry</button>
            </div>
          ) : offers.length === 0 ? (
            <div className="text-center py-5">
              <p className="text-muted">No active offers at the moment. Check back soon!</p>
            </div>
          ) : (
            <div className="row justify-content-center g-4">
              {offers.map((offer, index) => {
                const id = offer.id || offer._id;
                const title = offer.title || 'Special Offer';
                const image = offer.image_url || offer.image || fallbackImages[index % fallbackImages.length];
                const scheme = colorSchemes[index % colorSchemes.length];
                const daysLeft = getDaysLeft(offer.end_date);

                let discountText = 'Special';
                if (offer.discount_percentage) discountText = `Save ${offer.discount_percentage}%`;
                else if (offer.discount_amount) discountText = `Save Rs. ${Number(offer.discount_amount).toLocaleString()}`;

                // Build booking link
                let bookingLink = `/appointments?type=deal&offerId=${id}&item=${encodeURIComponent(title)}`;
                if (offer.service_id) bookingLink += `&serviceId=${offer.service_id}`;
                if (offer.course_id) bookingLink += `&courseId=${offer.course_id}`;

                return (
                  <div key={id} className="col-lg-4 col-md-6">
                    <div className="card h-100 deal-card shadow-lg border-0 rounded-4 overflow-hidden position-relative">
                      <img
                        src={image}
                        className="card-img-top w-100"
                        style={{ height: '220px', objectFit: 'cover' }}
                        alt={title}
                        onError={(e) => { e.target.src = fallbackImages[index % fallbackImages.length]; }}
                      />
                      <div
                        className={`deal-header ${scheme.header} text-white text-center py-3`}
                        style={scheme.headerStyle || {}}
                      >
                        <h4 className="mb-0 fw-bold">{title}</h4>
                        <span className={`badge ${scheme.badge} mt-2 px-3 py-1 rounded-pill`}>{discountText}</span>
                      </div>
                      <div className="card-body p-4 text-center d-flex flex-column">
                        {daysLeft && (
                          <p className={`mb-3 fw-bold ${daysLeft === 'Expired' ? 'text-danger' : 'text-success'}`}>
                            <i className="bi bi-clock me-1"></i>{daysLeft}
                          </p>
                        )}
                        {offer.description && (
                          <p className="text-muted mb-4">{offer.description}</p>
                        )}
                        <Link
                          to={bookingLink}
                          className={`btn ${scheme.btn} btn-lg rounded-pill w-100 mt-auto fw-bold shadow-sm grab-deal-btn`}
                        >
                          Grab Deal
                        </Link>
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

export default Deals;
