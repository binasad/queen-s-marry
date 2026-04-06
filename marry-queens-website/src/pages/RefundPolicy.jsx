import React from 'react';

const RefundPolicy = () => {
    return (
        <div className="bg-light pb-5">
            <section className="text-white text-center d-flex align-items-center justify-content-center mb-5"
                style={{
                    background: 'linear-gradient(rgba(143, 40, 77, 0.8), rgba(143, 40, 77, 0.9)), url("/images/massage.jpg") center/cover',
                    minHeight: '40vh',
                    position: 'relative',
                }}>
                <div className="container position-relative" style={{ zIndex: 1 }}>
                    <h1 className="display-3 fw-bold mb-3">Refund & Cancellation</h1>
                    <p className="lead mb-0" style={{ maxWidth: '700px', margin: '0 auto', color: 'rgba(255,255,255,0.9)' }}>
                        Fair rules for cancellations, rescheduling, and refund requests.
                    </p>
                </div>
            </section>

            <div className="container">
                <div className="row justify-content-center">
                    <div className="col-lg-10">
                        <div className="card border-0 shadow-sm rounded-4 p-4 p-md-5 bg-white">
                            <div className="legal-content">
                                <h3 className="fw-bold mb-4">1. Appointment Cancellations</h3>
                                <p>We understand that schedules change. To respect our stylists' time, we request at least 24 hours' notice for any cancellation. If you cancel within 24 hours of your appointment, a cancellation fee of 50% of the service cost may apply.</p>

                                <h3 className="fw-bold mt-5 mb-4">2. Online Pre-Payments</h3>
                                <p>For appointments with online pre-payments, a full refund will be issued if the cancellation is made at least 48 hours in advance. No refunds for same-day cancellations or no-shows.</p>

                                <h3 className="fw-bold mt-5 mb-4">3. Course Refunds</h3>
                                <p>Fees for training courses are generally non-refundable once the course has started. If a student withdraws at least 7 days before the start date, a 75% refund of the course fee will be issued.</p>

                                <h3 className="fw-bold mt-5 mb-4">4. Deal & Offer Purchases</h3>
                                <p>Once purchased, special beauty deals, combos, and offers are non-refundable and must be used within the specified validity period. Deals cannot be exchanged for cash or other services.</p>

                                <h3 className="fw-bold mt-5 mb-4">5. Rescheduling</h3>
                                <p>Rescheduling is permitted with at least 12 hours' notice at no extra charge. Repeated rescheduling may require a deposit to be paid in advance.</p>

                                <h3 className="fw-bold mt-5 mb-4">6. Processing Times</h3>
                                <p>Approved refunds will be processed back to the original payment method within 7-10 business days. Bank processing times may vary.</p>

                                <p className="mt-5 text-muted small text-center">Last Updated: April 2024</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default RefundPolicy;
