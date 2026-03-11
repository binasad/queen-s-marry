import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';

const validItems = {
    service: [
        { value: "hair_styling", label: "Hair Styling" },
        { value: "makeup", label: "Bridal / Party Makeup" },
        { value: "facial", label: "Facial / Skin Care" },
        { value: "massage", label: "Massage / Spa" },
        { value: "nails", label: "Manicure & Pedicure" },
        { value: "threading", label: "Threading & Waxing" }
    ],
    course: [
        { value: "basic_beautician", label: "Basic Beautician Course (3 Months)" },
        { value: "advanced_makeup", label: "Advanced Makeup Pro (6 Months)" },
        { value: "bridal_masterclass", label: "Bridal Masterclass (1 Month)" },
        { value: "hair_specialist", label: "Hair Specialist Course (2 Months)" }
    ],
    deal: [
        { value: "bridal_special", label: "Bridal Special - 20% Off" },
        { value: "glow_and_go", label: "Glow & Go - 30% Off" },
        { value: "party_ready", label: "Party Ready - 15% Off" },
        { value: "spa_day", label: "Ultimate Spa Day - 25% Off" }
    ]
};

const Appointments = () => {
    const [searchParams] = useSearchParams();
    
    // Form State
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        phone: '',
        category: '',
        specificItem: '',
        date: '',
        time: '',
        notes: ''
    });

    const [status, setStatus] = useState({ type: '', message: '' });

    // Handle initial URL parameters (like ?type=course&item=basic_beautician)
    useEffect(() => {
        const typeParam = searchParams.get('type');
        const itemParam = searchParams.get('item');
        
        if (typeParam && validItems[typeParam]) {
            setFormData(prev => ({ ...prev, category: typeParam }));
            
            // Check if the itemParam is valid for this category
            if (itemParam && validItems[typeParam].some(i => i.value === itemParam)) {
               // We need a slight timeout because state updates are batched, 
               // and we just set the category.
               setTimeout(() => {
                   setFormData(prev => ({ ...prev, specificItem: itemParam }));
               }, 0);
            }
        }
    }, [searchParams]);

    // Setup minimum date to today
    const [minDate, setMinDate] = useState('');
    useEffect(() => {
        const today = new Date().toISOString().split('T')[0];
        setMinDate(today);
    }, []);

    const handleChange = (e) => {
        const { id, value } = e.target;
        
        setFormData(prev => {
            const newData = { ...prev, [id]: value };
            // If category changes, reset the specific item
            if (id === 'category') {
                newData.specificItem = '';
            }
            return newData;
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        // Basic Validation
        if (!formData.name || !formData.email || !formData.phone || !formData.category || !formData.specificItem || !formData.date || !formData.time) {
            setStatus({ type: 'error', message: 'Please fill in all required fields.' });
            return;
        }

        // Time Validation (9 AM to 9 PM)
        const selectedTime = formData.time;
        if (selectedTime < "09:00" || selectedTime > "21:00") {
            setStatus({ type: 'error', message: 'Please select a time between 9:00 AM and 9:00 PM.' });
            return;
        }

        setStatus({ type: 'loading', message: 'Sending booking request...' });

        try {
            const response = await fetch('http://localhost:5000/api/v1/public/appointments', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(formData)
            });
            
            const data = await response.json();
            
            if(response.ok || response.status === 201) {
               setStatus({ type: 'success', message: 'Booking Confirmed! An email has been sent to ' + formData.email });
               setFormData({ name: '', email: '', phone: '', category: '', specificItem: '', date: '', time: '', notes: '' });
            } else {
               setStatus({ type: 'error', message: data.message || 'Failed to book appointment' });
            }

        } catch (error) {
            console.error("Booking error:", error);
            setStatus({ type: 'error', message: 'Server is currently unreachable. Please try again later.' });
        }
    };

    return (
        <>
            <section className="appointment-hero bg-dark text-white text-center py-5" style={{ background: 'linear-gradient(rgba(0,0,0,0.7), rgba(0,0,0,0.7)), url("/images/salon-interior.jpg") center/cover' }}>
                <div className="container py-4">
                    <h1 className="display-4 fw-bold mb-3">Book an Appointment</h1>
                    <p className="lead">Reserve your spot and let us pamper you.</p>
                </div>
            </section>

            <section className="appointment-form-section py-5 bg-light">
                <div className="container">
                    <div className="row justify-content-center">
                        <div className="col-lg-8">
                            <div className="card shadow-lg border-0 rounded-4">
                                <div className="card-body p-5">
                                    <h3 className="fw-bold mb-4 text-center text-gradient">Your Details</h3>
                                    
                                    {status.message && (
                                        <div className={`alert ${status.type === 'error' ? 'alert-danger' : status.type === 'success' ? 'alert-success' : 'alert-info'} mb-4`} role="alert">
                                            {status.type === 'loading' ? (
                                                 <><span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span> {status.message}</>
                                            ) : status.message}
                                        </div>
                                    )}

                                    <form id="bookingForm" onSubmit={handleSubmit}>
                                        <div className="row g-3">
                                            <div className="col-md-6">
                                                <label htmlFor="name" className="form-label fw-bold">Full Name <span className="text-danger">*</span></label>
                                                <input type="text" className="form-control px-3 py-2" id="name" value={formData.name} onChange={handleChange} required placeholder="Jane Doe" />
                                            </div>
                                            <div className="col-md-6">
                                                <label htmlFor="email" className="form-label fw-bold">Email Address <span className="text-danger">*</span></label>
                                                <input type="email" className="form-control px-3 py-2" id="email" value={formData.email} onChange={handleChange} required placeholder="jane@example.com" />
                                            </div>
                                            
                                            <div className="col-md-12">
                                                <label htmlFor="phone" className="form-label fw-bold">Phone Number <span className="text-danger">*</span></label>
                                                <input type="tel" className="form-control px-3 py-2" id="phone" value={formData.phone} onChange={handleChange} required placeholder="0300-1234567" />
                                            </div>

                                            <div className="col-md-6">
                                                <label htmlFor="category" className="form-label fw-bold">Selection Type <span className="text-danger">*</span></label>
                                                <select className="form-select px-3 py-2" id="category" value={formData.category} onChange={handleChange} required>
                                                    <option value="" disabled>Choose type...</option>
                                                    <option value="service">Individual Service</option>
                                                    <option value="course">Training Course</option>
                                                    <option value="deal">Special Deal/Offer</option>
                                                </select>
                                            </div>

                                            <div className="col-md-6">
                                                <label htmlFor="specificItem" className="form-label fw-bold">Specific Item <span className="text-danger">*</span></label>
                                                <select className="form-select px-3 py-2" id="specificItem" value={formData.specificItem} onChange={handleChange} required disabled={!formData.category}>
                                                    <option value="" disabled>Select an option...</option>
                                                    {formData.category && validItems[formData.category].map(item => (
                                                        <option key={item.value} value={item.value}>{item.label}</option>
                                                    ))}
                                                </select>
                                            </div>

                                            <div className="col-md-6">
                                                <label htmlFor="date" className="form-label fw-bold">Date <span className="text-danger">*</span></label>
                                                <input type="date" className="form-control px-3 py-2" id="date" value={formData.date} onChange={handleChange} min={minDate} required />
                                            </div>
                                            <div className="col-md-6">
                                                <label htmlFor="time" className="form-label fw-bold">Time (9 AM - 9 PM) <span className="text-danger">*</span></label>
                                                <input type="time" className="form-control px-3 py-2" id="time" value={formData.time} onChange={handleChange} min="09:00" max="21:00" required />
                                            </div>

                                            <div className="col-12 mt-4">
                                                <label htmlFor="notes" className="form-label fw-bold">Special Requests (Optional)</label>
                                                <textarea className="form-control px-3 py-2" id="notes" rows="3" value={formData.notes} onChange={handleChange} placeholder="Any specific requirements or questions?"></textarea>
                                            </div>

                                            <div className="col-12 mt-4 text-center">
                                                <button type="submit" className="btn btn-gradient btn-lg px-5 rounded-pill w-100 fw-bold" disabled={status.type === 'loading'}>
                                                    Submit Booking Request
                                                </button>
                                                <p className="text-muted mt-3 small"><i className="bi bi-info-circle me-1"></i> You will receive an email confirmation shortly after booking.</p>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </>
    );
};

export default Appointments;
