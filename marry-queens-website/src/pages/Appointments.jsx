import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { getServices, getCourses, getOffers, createAppointment, applyCourse } from '../services/api';

const Appointments = () => {
    const [searchParams] = useSearchParams();

    // API data for dropdowns
    const [servicesData, setServicesData] = useState([]);
    const [coursesData, setCoursesData] = useState([]);
    const [offersData, setOffersData] = useState([]);
    const [dataLoading, setDataLoading] = useState(true);

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

    // Load dropdown data from API
    useEffect(() => {
        async function loadData() {
            try {
                const [services, courses, offers] = await Promise.all([
                    getServices().catch(() => []),
                    getCourses().catch(() => []),
                    getOffers().catch(() => []),
                ]);
                setServicesData(services);
                setCoursesData(courses);
                setOffersData(offers);
            } catch (err) {
                console.error('Failed to load dropdown data:', err);
            } finally {
                setDataLoading(false);
            }
        }
        loadData();
    }, []);

    // Handle URL parameters
    useEffect(() => {
        if (dataLoading) return;

        const typeParam = searchParams.get('type');
        const itemParam = searchParams.get('item');
        const serviceId = searchParams.get('serviceId');
        const courseId = searchParams.get('courseId');
        const offerId = searchParams.get('offerId');
        const categoryId = searchParams.get('categoryId');

        if (typeParam) {
            setFormData(prev => ({ ...prev, category: typeParam }));

            setTimeout(() => {
                if (typeParam === 'service' && serviceId) {
                    setFormData(prev => ({ ...prev, specificItem: serviceId }));
                } else if (typeParam === 'service' && categoryId && servicesData.length) {
                    // Pre-select first service in this category
                    const svc = servicesData.find(s => s.categoryId === categoryId || s.category_id === categoryId);
                    if (svc) setFormData(prev => ({ ...prev, specificItem: svc.id || svc._id }));
                } else if (typeParam === 'course' && courseId) {
                    setFormData(prev => ({ ...prev, specificItem: courseId }));
                } else if (typeParam === 'deal' && offerId) {
                    setFormData(prev => ({ ...prev, specificItem: offerId }));
                }
            }, 0);
        }
    }, [searchParams, dataLoading, servicesData]);

    // Setup minimum date to today
    const [minDate, setMinDate] = useState('');
    useEffect(() => {
        setMinDate(new Date().toISOString().split('T')[0]);
    }, []);

    // Build dropdown items based on selected category
    function getDropdownItems() {
        switch (formData.category) {
            case 'service':
                return servicesData.map(s => ({
                    value: s.id || s._id,
                    label: `${s.name} - Rs. ${Number(s.price || 0).toLocaleString()}`
                }));
            case 'course':
                return coursesData.map(c => ({
                    value: c.id || c._id,
                    label: `${c.title} - Rs. ${Number(c.price || 0).toLocaleString()}`
                }));
            case 'deal':
                return offersData.map(o => {
                    const disc = o.discount_percentage ? `${o.discount_percentage}% OFF` : o.discount_amount ? `Rs. ${o.discount_amount} OFF` : '';
                    return {
                        value: o.id || o._id,
                        label: `${o.title}${disc ? ' (' + disc + ')' : ''}`
                    };
                });
            default:
                return [];
        }
    }

    const handleChange = (e) => {
        const { id, value } = e.target;
        setFormData(prev => {
            const newData = { ...prev, [id]: value };
            if (id === 'category') newData.specificItem = '';
            return newData;
        });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!formData.name || !formData.phone || !formData.category || !formData.specificItem || !formData.date || !formData.time) {
            setStatus({ type: 'error', message: 'Please fill in all required fields.' });
            return;
        }

        if (formData.time < "09:00" || formData.time > "21:00") {
            setStatus({ type: 'error', message: 'Please select a time between 9:00 AM and 9:00 PM.' });
            return;
        }

        setStatus({ type: 'loading', message: 'Sending booking request...' });

        const offerId = searchParams.get('offerId') || undefined;

        try {
            if (formData.category === 'course') {
                await applyCourse(formData.specificItem, {
                    customerName: formData.name,
                    customerPhone: formData.phone,
                    customerEmail: formData.email || undefined,
                    offerId,
                });
            } else if (formData.category === 'service') {
                await createAppointment({
                    serviceId: formData.specificItem,
                    appointmentDate: formData.date,
                    appointmentTime: formData.time,
                    customerName: formData.name,
                    customerPhone: formData.phone,
                    customerEmail: formData.email || undefined,
                    payNow: false,
                    offerId,
                });
            } else if (formData.category === 'deal') {
                const offer = offersData.find(o => (o.id || o._id) === formData.specificItem);
                if (offer?.service_id) {
                    await createAppointment({
                        serviceId: offer.service_id,
                        appointmentDate: formData.date,
                        appointmentTime: formData.time,
                        customerName: formData.name,
                        customerPhone: formData.phone,
                        customerEmail: formData.email || undefined,
                        payNow: false,
                        offerId: offer.id || offer._id,
                    });
                } else if (offer?.course_id) {
                    await applyCourse(offer.course_id, {
                        customerName: formData.name,
                        customerPhone: formData.phone,
                        customerEmail: formData.email || undefined,
                        offerId: offer.id || offer._id,
                    });
                } else {
                    await createAppointment({
                        serviceId: formData.specificItem,
                        appointmentDate: formData.date,
                        appointmentTime: formData.time,
                        customerName: formData.name,
                        customerPhone: formData.phone,
                        customerEmail: formData.email || undefined,
                        payNow: false,
                        offerId: offer?.id || offer?._id,
                    });
                }
            }

            setStatus({ type: 'success', message: 'Booking Confirmed! We will contact you shortly at ' + formData.phone });
            setFormData({ name: '', email: '', phone: '', category: '', specificItem: '', date: '', time: '', notes: '' });

        } catch (error) {
            console.error("Booking error:", error);
            setStatus({ type: 'error', message: error.message || 'Failed to book. Please try again or call +92-308-5494369.' });
        }
    };

    const dropdownItems = getDropdownItems();

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
                                    <div className="text-center py-4">
                                        <div className="mb-4">
                                            <i className="bi bi-phone text-gradient display-1"></i>
                                        </div>
                                        <h2 className="fw-bold mb-3">Bookings Are Now on Our App!</h2>
                                        <p className="lead text-muted mb-5">
                                            For a faster, smoother, and more personalized booking experience, please download the official Queen's Merry Beauty Saloon app.
                                        </p>
                                        <div className="d-flex justify-content-center gap-3 flex-wrap">
                                            <a href="#" className="btn btn-dark btn-lg px-4 py-3 rounded-pill d-flex align-items-center">
                                                <i className="bi bi-apple fs-4 me-2"></i>
                                                <div className="text-start" style={{ lineHeight: '1.2' }}>
                                                    <small className="d-block" style={{ fontSize: '10px' }}>Download on the</small>
                                                    <strong className="fs-6">App Store</strong>
                                                </div>
                                            </a>
                                            <a href="#" className="btn btn-dark btn-lg px-4 py-3 rounded-pill d-flex align-items-center">
                                                <i className="bi bi-google-play fs-4 me-2"></i>
                                                <div className="text-start" style={{ lineHeight: '1.2' }}>
                                                    <small className="d-block" style={{ fontSize: '10px' }}>GET IT ON</small>
                                                    <strong className="fs-6">Google Play</strong>
                                                </div>
                                            </a>
                                        </div>
                                        <p className="mt-5 text-muted small">
                                            Questions? Call us at <strong>+92-308-5494369</strong>
                                        </p>
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

export default Appointments;
