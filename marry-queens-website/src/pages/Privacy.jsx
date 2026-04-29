import React from 'react';

const Privacy = () => {
    return (
        <div className="bg-light pb-5">
            <section className="text-white text-center d-flex align-items-center justify-content-center mb-5"
                style={{
                    background: 'linear-gradient(rgba(143, 40, 77, 0.8), rgba(143, 40, 77, 0.9)), url("/images/facial.jpg") center/cover',
                    minHeight: '40vh',
                    position: 'relative',
                }}>
                <div className="container position-relative" style={{ zIndex: 1 }}>
                    <h1 className="display-3 fw-bold mb-3">Privacy Policy</h1>
                    <p className="lead mb-0" style={{ maxWidth: '700px', margin: '0 auto', color: 'rgba(255,255,255,0.9)' }}>
                        How we protect your personal information and maintain your trust.
                    </p>
                </div>
            </section>

            <div className="container">
                <div className="row justify-content-center">
                    <div className="col-lg-10">
                        <div className="card border-0 shadow-sm rounded-4 p-4 p-md-5 bg-white">
                            <div className="legal-content">
                                <h3 className="fw-bold mb-4">1. Personal Information</h3>
                                <p>We collect personal information such as your name, email, and phone number when you book an appointment, register for a course, or contact us. This information is used ONLY for fulfilling your request and communicating with you about our services.</p>

                                <h3 className="fw-bold mt-5 mb-4">2. Payment Data</h3>
                                <p>For online payments, we use secure, third-party payment gateways. We do NOT store your full credit card details or bank account information on our servers. All financial data is processed via encrypted channels by our payment partners.</p>

                                <h3 className="fw-bold mt-5 mb-4">3. Use of Cookies</h3>
                                <p>Our website uses cookies to enhance your browsing experience, analyze site traffic, and remember your preferences. You can manage cookie settings through your browser at any time.</p>

                                <h3 className="fw-bold mt-5 mb-4">4. Third-Party Sharing</h3>
                                <p>We do NOT sell, trade, or share your personal information with third parties for marketing purposes. Your data is only shared with trusted service providers who assist us in operating our saloon or app, subject to strict confidentiality agreements.</p>

                                <h3 className="fw-bold mt-5 mb-4">5. Security Measures</h3>
                                <p>We implement technical and organizational security measures to protect your data from unauthorized access, loss, or misuse. This includes SSL encryption for all web traffic.</p>

                                <h3 className="fw-bold mt-5 mb-4">6. Your Rights</h3>
                                <p>You have the right to access, correct, or request the deletion of your personal data. Contact us at info@queensmarry.com to exercise these rights.</p>

                                <p className="mt-5 text-muted small text-center">Last Updated: April 2024</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Privacy;
