import { Link } from 'react-router-dom';

const Courses = () => {
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
                    <div className="row g-4">

                        {/* Basic Course */}
                        <div className="col-lg-4 col-md-6">
                            <div className="card h-100 course-card shadow-sm border-0 rounded-4 overflow-hidden position-relative">
                                <div className="card-img-wrapper" style={{ height: '200px', overflow: 'hidden' }}>
                                    <img src="/images/course-1.jpg" className="card-img-top w-100 h-100" style={{ objectFit: 'cover' }} alt="Basic Course" />
                                </div>
                                <div className="card-body p-4 d-flex flex-column">
                                    <div className="d-flex justify-content-between align-items-center mb-3">
                                        <h4 className="card-title fw-bold mb-0 text-dark">Basic Beautician</h4>
                                        <span className="badge bg-primary rounded-pill px-3 py-2 fs-6">3 Months</span>
                                    </div>
                                    <p className="card-text text-muted mb-3">
                                        Master the fundamentals of skin care, basic makeup, hair styling, and threading. Perfect for beginners.
                                    </p>
                                    <div className="d-flex justify-content-between align-items-center mt-auto pt-3 border-top">
                                        <span className="fs-4 fw-bold text-gradient">Rs. 25,000</span>
                                        <Link to="/appointments?type=course&item=basic_beautician" className="btn btn-outline-primary rounded-pill px-4 enroll-btn">Enroll Now</Link>
                                    </div>
                                </div>
                            </div>
                        </div>


                        {/* Advanced Course */}
                        <div className="col-lg-4 col-md-6">
                            <div className="card h-100 course-card shadow border-primary rounded-4 overflow-hidden position-relative">
                                <div className="position-absolute top-0 end-0 bg-primary text-white p-2 rounded-start-bottom shadow-sm" style={{ zIndex: 1 }}>Popular</div>
                                <div className="card-img-wrapper" style={{ height: '200px', overflow: 'hidden' }}>
                                    <img src="/images/course 2.jpg" className="card-img-top w-100 h-100" style={{ objectFit: 'cover' }} alt="Advanced Course" />
                                </div>
                                <div className="card-body p-4 d-flex flex-column">
                                    <div className="d-flex justify-content-between align-items-center mb-3">
                                        <h4 className="card-title fw-bold mb-0 text-dark">Advanced Makeup Pro</h4>
                                        <span className="badge bg-primary rounded-pill px-3 py-2 fs-6">6 Months</span>
                                    </div>
                                    <p className="card-text text-muted mb-3">
                                        Learn bridal, party, and HD makeup techniques along with advanced hair coloring and styling.
                                    </p>
                                    <div className="d-flex justify-content-between align-items-center mt-auto pt-3 border-top">
                                        <span className="fs-4 fw-bold text-gradient">Rs. 50,000</span>
                                        <Link to="/appointments?type=course&item=advanced_makeup" className="btn btn-primary btn-gradient text-white rounded-pill px-4 enroll-btn">Enroll Now</Link>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Masterclass */}
                        <div className="col-lg-4 col-md-6 mx-auto">
                            <div className="card h-100 course-card shadow-sm border-0 rounded-4 overflow-hidden position-relative">
                                <div className="card-img-wrapper" style={{ height: '200px', overflow: 'hidden' }}>
                                    <img src="/images/course-3.jpg" className="card-img-top w-100 h-100" style={{ objectFit: 'cover' }} alt="Masterclass" />
                                </div>
                                <div className="card-body p-4 d-flex flex-column">
                                    <div className="d-flex justify-content-between align-items-center mb-3">
                                        <h4 className="card-title fw-bold mb-0 text-dark">Bridal Masterclass</h4>
                                        <span className="badge bg-primary rounded-pill px-3 py-2 fs-6">1 Month</span>
                                    </div>
                                    <p className="card-text text-muted mb-3">
                                        An intensive bootcamp focused purely on high-end bridal makeup and intricate hair updos.
                                    </p>
                                    <div className="d-flex justify-content-between align-items-center mt-auto pt-3 border-top">
                                        <span className="fs-4 fw-bold text-gradient">Rs. 30,000</span>
                                        <Link to="/appointments?type=course&item=bridal_masterclass" className="btn btn-outline-primary rounded-pill px-4 enroll-btn">Enroll Now</Link>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </section>
        </>
    );
};

export default Courses;
