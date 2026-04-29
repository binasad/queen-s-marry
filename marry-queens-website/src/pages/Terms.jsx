import React from 'react';

const Terms = () => {
    return (
        <div className="bg-light pb-5">
            <section className="text-white text-center d-flex align-items-center justify-content-center mb-5"
                style={{
                    background: 'linear-gradient(rgba(143, 40, 77, 0.8), rgba(143, 40, 77, 0.9)), url("/images/salon-interior.jpg") center/cover',
                    minHeight: '40vh',
                    position: 'relative',
                }}>
                <div className="container position-relative" style={{ zIndex: 1 }}>
                    <h1 className="display-3 fw-bold mb-3">Terms & Conditions</h1>
                    <p className="lead mb-0" style={{ maxWidth: '700px', margin: '0 auto', color: 'rgba(255,255,255,0.9)' }}>
                        Please read these terms carefully before using our services.
                    </p>
                </div>
            </section>

            <div className="container">
                <div className="row justify-content-center">
                    <div className="col-lg-10">
                        <div className="card border-0 shadow-sm rounded-4 p-4 p-md-5 bg-white">
                            <div className="legal-content">
                                <h3 className="fw-bold mb-4">1. Acceptance of Terms</h3>
                                <p>By accessing and using the Queen's Merry Beauty Saloon website and mobile application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.</p>

                                <h3 className="fw-bold mt-5 mb-4">2. Appointment Bookings</h3>
                                <p>Appointments can be booked via our website, mobile app, or by phone. We recommend booking in advance to ensure availability. We reserve the right to refuse service to anyone for any reason at any time.</p>

                                <h3 className="fw-bold mt-5 mb-4">3. Payments</h3>
                                <p>Payments for services, courses, or deals can be made online via our integrated payment gateways or in person at the saloon. All online transactions are secure and encrypted.</p>

                                <h3 className="fw-bold mt-5 mb-4">4. Cancellation & No-Show Policy</h3>
                                <p>We require at least 24 hours' notice for cancellations. Repeated no-shows or late cancellations may result in a requirement for non-refundable deposits for future bookings.</p>

                                <h3 className="fw-bold mt-5 mb-4">5. Use of Site Content</h3>
                                <p>All content on this site, including images, text, and logos, is the property of Queen's Merry Beauty Saloon and is protected by copyright laws. Unauthorized use is strictly prohibited.</p>

                                <h3 className="fw-bold mt-5 mb-4">6. Limitation of Liability</h3>
                                <p>Queen's Merry Beauty Saloon is not liable for any direct, indirect, incidental, or consequential damages arising from the use of our website or services.</p>

                                <h3 className="fw-bold mt-5 mb-4">7. Changes to Terms</h3>
                                <p>We reserve the right to update these terms at any time. Changes will be posted on this page with an updated revision date.</p>
                                
                                <p className="mt-5 text-muted small text-center">Last Updated: April 2024</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Terms;
