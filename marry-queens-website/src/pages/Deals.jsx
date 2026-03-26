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
            
            // Hardcoded deals to blend with API deals so we always have beautifully populated cards (like it was before)
            const hardcodedDeals = [
                {
                    _id: 'deal-1',
                    title: 'Bridal Package',
                    discount_label: 'Flat 20% OFF',
                    price: 25000,
                    old_price: 32000,
                    description: 'HD Bridal Makeup, Advanced Hair Styling, Premium Mehendi',
                    image: '/images/bride.webp'
                },
                {
                    _id: 'deal-2',
                    title: 'Party Makeover',
                    discount_label: 'Save Rs. 2000',
                    price: 8000,
                    old_price: 10000,
                    description: 'Flawless Base, Soft Glam Eyes, Blowdry & Setting',
                    image: '/images/makeup.jpeg'
                },
                {
                    _id: 'deal-3',
                    title: 'Skin Rejuvenation',
                    discount_label: 'Best Value',
                    price: 4500,
                    old_price: 5500,
                    description: 'Deep Cleansing Facial, Manicure, Pedicure',
                    image: '/images/hydrafacial.jpg'
                }
            ];
            
            // Filter out broken API entries (e.g. ones with no price value to prevent NaN)
            const validData = data.filter(offer => offer.price || offer.discounted_price || offer.new_price || offer.original_price);
            
            // If the API only has 1 or 2 valid deals, add the hardcoded ones to fill the grid up to at least 3
            if (validData.length < 3) {
                const combined = [...validData, ...hardcodedDeals.slice(0, Math.max(0, 3 - validData.length))];
                setOffers(combined);
            } else {
                setOffers(validData);
            }
        } catch (err) {
            console.error('Failed to load offers:', err);
            setError('Unable to load exclusive offers at the moment.');
        } finally {
            setLoading(false);
        }
    }

    const fallbackImages = ['/images/waxing.png', '/images/massage-hero.jpeg', '/images/haircut.jpg'];

    return (
        <>
            {/* ── Premium Hero ── */}
            <section
                className="text-white text-center d-flex align-items-center justify-content-center"
                style={{
                    backgroundImage: 'url("/images/makeup hero.jpg")',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    minHeight: '60vh',
                    position: 'relative',
                }}
            >
                <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, rgba(0,0,0,0.55) 60%, rgba(255,255,255,0.05) 100%)' }} />
                <div className="container position-relative" style={{ zIndex: 1 }}>
                    <span
                        className="d-inline-block fw-bold text-uppercase mb-3"
                        style={{ color: '#FF80A5', letterSpacing: '0.18em', fontSize: '0.85rem' }}
                    >
                        Exclusive Offers
                    </span>
                    <h1 className="display-3 fw-bold mb-3">Beauty Deals & Combos</h1>
                    <p className="lead mb-0" style={{ maxWidth: '600px', margin: '0 auto', color: 'rgba(255,255,255,0.85)' }}>
                        Hurry up! Grab our limited-time beauty combos at unbeatable prices.
                    </p>
                </div>
            </section>

            {/* ── Deals List ── */}
            <section className="deals-list py-5 bg-light">
                <div className="container">
                    {loading ? (
                        <div className="text-center py-5">
                            <div className="spinner-border text-primary" role="status"></div>
                            <p className="mt-3 text-muted">Fetching latest deals...</p>
                        </div>
                    ) : error ? (
                        <div className="text-center py-5">
                            <p className="text-muted">{error}</p>
                            <button className="btn btn-gradient mt-2" onClick={loadOffers}>Retry</button>
                        </div>
                    ) : offers.length === 0 ? (
                        <div className="text-center py-5">
                            <p className="text-muted">No active deals right now. Check back soon!</p>
                        </div>
                    ) : (
                        <div className="row justify-content-center g-4">
                            {offers.map((offer, index) => {
                                const id = offer.id || offer._id;
                                const title = offer.title || 'Special Deal';
                                const discountLabel = offer.discount_label || offer.discount || 'Special Offer';
                                const oldPrice = offer.original_price || offer.old_price;
                                const newPrice = offer.discounted_price || offer.price || offer.new_price;
                                const descriptionParts = offer.description ? offer.description.split(',').map(s => s.trim()) : [];
                                const image = offer.image_url || offer.image || fallbackImages[index % fallbackImages.length];

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
                                            <div className="deal-header bg-danger text-white text-center py-3">
                                                <h4 className="mb-0 fw-bold">{title}</h4>
                                                <span className="badge bg-white text-danger mt-2 px-3 py-1 rounded-pill">{discountLabel}</span>
                                            </div>
                                            <div className="card-body p-4 text-center d-flex flex-column">
                                                <h2 className="display-6 fw-bold text-dark mb-4">
                                                    Rs. {Number(newPrice).toLocaleString()}
                                                    {oldPrice && (
                                                        <span className="text-decoration-line-through text-muted fs-5 ms-2">
                                                            Rs. {Number(oldPrice).toLocaleString()}
                                                        </span>
                                                    )}
                                                </h2>
                                                {descriptionParts.length > 0 && (
                                                    <ul className="list-unstyled text-start mb-4 text-muted mx-auto" style={{ maxWidth: '80%' }}>
                                                        {descriptionParts.map((part, i) => (
                                                            <li key={i} className="mb-2">
                                                                <i className="bi bi-check2-circle text-success me-2"></i> {part}
                                                            </li>
                                                        ))}
                                                    </ul>
                                                )}
                                                <Link
                                                    to={`/appointments?type=deal&dealId=${id}&item=${encodeURIComponent(title)}`}
                                                    className="btn btn-danger btn-lg rounded-pill w-100 mt-auto fw-bold shadow-sm grab-deal-btn"
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
