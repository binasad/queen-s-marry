import { Link } from 'react-router-dom';

const Deals = () => {
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
                    <div className="row justify-content-center g-4">

                        <div className="col-lg-4 col-md-6">
                            <div className="card h-100 deal-card shadow-lg border-0 rounded-4 overflow-hidden position-relative">
                                <img src="/images/bride.webp" className="card-img-top w-100" style={{ height: '220px', objectFit: 'cover' }} alt="Bridal Special" />
                                <div className="deal-header bg-danger text-white text-center py-3">
                                    <h4 className="mb-0 fw-bold">Bridal Special</h4>
                                    <span className="badge bg-white text-danger mt-2 px-3 py-1 rounded-pill">Save 20%</span>
                                </div>
                                <div className="card-body p-4 text-center d-flex flex-column">
                                    <h2 className="display-6 fw-bold text-dark mb-4">Rs. 15,000 <span className="text-decoration-line-through text-muted fs-5">Rs. 18,750</span></h2>
                                    <ul className="list-unstyled text-start mb-4 text-muted mx-auto" style={{ maxWidth: '80%' }}>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-success me-2"></i> Bridal Makeup (HD)</li>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-success me-2"></i> Bridal Hair Styling</li>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-success me-2"></i> Manicure & Pedicure</li>
                                        <li><i className="bi bi-check2-circle text-success me-2"></i> Free Threading</li>
                                    </ul>
                                    <Link to="/appointments?type=deal&item=bridal_special" className="btn btn-danger btn-lg rounded-pill w-100 mt-auto fw-bold shadow-sm grab-deal-btn">Grab Deal</Link>
                                </div>
                            </div>
                        </div>

                        <div className="col-lg-4 col-md-6">
                            <div className="card h-100 deal-card shadow-lg border-primary rounded-4 overflow-hidden position-relative transform-scale">
                                <div className="position-absolute top-0 end-0 bg-warning text-dark fw-bold p-2 px-3 rounded-start-bottom shadow" style={{ zIndex: 1, transform: 'rotate(0deg)' }}>Bestseller</div>
                                <img src="/images/makeup.jpeg" className="card-img-top w-100" style={{ height: '220px', objectFit: 'cover' }} alt="Glow & Go" />
                                <div className="deal-header text-white text-center py-3" style={{ background: 'linear-gradient(135deg, #FF758C 0%, #9D50BB 100%)' }}>
                                    <h4 className="mb-0 fw-bold">Glow & Go</h4>
                                    <span className="badge bg-white text-primary mt-2 px-3 py-1 rounded-pill">Save 30%</span>
                                </div>
                                <div className="card-body p-4 text-center d-flex flex-column">
                                    <h2 className="display-6 fw-bold text-dark mb-4">Rs. 5,000 <span className="text-decoration-line-through text-muted fs-5">Rs. 7,150</span></h2>
                                    <ul className="list-unstyled text-start mb-4 text-muted mx-auto" style={{ maxWidth: '80%' }}>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-primary me-2"></i> Whitening Facial</li>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-primary me-2"></i> Hair Trimming</li>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-primary me-2"></i> Eyebrow & Upper Lip</li>
                                        <li><i className="bi bi-check2-circle text-primary me-2"></i> Relaxing Head Massage</li>
                                    </ul>
                                    <Link to="/appointments?type=deal&item=glow_and_go" className="btn btn-primary btn-gradient btn-lg w-100 rounded-pill mt-auto fw-bold shadow-sm grab-deal-btn">Grab Deal</Link>
                                </div>
                            </div>
                        </div>

                        <div className="col-lg-4 col-md-6 mx-auto">
                            <div className="card h-100 deal-card shadow-lg border-0 rounded-4 overflow-hidden position-relative">
                                <img src="/images/haircut.jpg" className="card-img-top w-100" style={{ height: '220px', objectFit: 'cover' }} alt="Party Ready" />
                                <div className="deal-header bg-dark text-white text-center py-3">
                                    <h4 className="mb-0 fw-bold">Party Ready</h4>
                                    <span className="badge bg-light text-dark mt-2 px-3 py-1 rounded-pill">Save 15%</span>
                                </div>
                                <div className="card-body p-4 text-center d-flex flex-column">
                                    <h2 className="display-6 fw-bold text-dark mb-4">Rs. 8,500 <span className="text-decoration-line-through text-muted fs-5">Rs. 10,000</span></h2>
                                    <ul className="list-unstyled text-start mb-4 text-muted mx-auto" style={{ maxWidth: '80%' }}>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-dark me-2"></i> Party Makeup</li>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-dark me-2"></i> Hair Blowdry / Curls</li>
                                        <li className="mb-2"><i className="bi bi-check2-circle text-dark me-2"></i> Nail Polish Application</li>
                                        <li><i className="bi bi-check2-circle text-dark me-2"></i> Face Polish</li>
                                    </ul>
                                    <Link to="/appointments?type=deal&item=party_ready" className="btn btn-dark btn-lg w-100 rounded-pill mt-auto fw-bold shadow-sm grab-deal-btn">Grab Deal</Link>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </section>
        </>
    );
};

export default Deals;
