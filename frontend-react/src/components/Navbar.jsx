import { Link, useLocation } from 'react-router-dom';

const Navbar = () => {
  const location = useLocation();
  const currentPath = location.pathname;

  return (
    <nav className="navbar navbar-expand-lg navbar-dark bg-dark sticky-top">
      <div className="container">
        <Link className="navbar-brand d-flex align-items-center" to="/">
          <img src="/images/logo.png" alt="Logo" style={{ height: '40px' }} />
          <span className="brand-text ms-2 fw-bold text-white">Merry Queens Salon</span>
        </Link>
        <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
          <span className="navbar-toggler-icon"></span>
        </button>
        <div className="collapse navbar-collapse justify-content-end" id="navbarNav">
          <ul className="navbar-nav">
            <li className="nav-item">
              <Link className={`nav-link ${currentPath === '/' ? 'active' : ''}`} to="/">Home</Link>
            </li>
            <li className="nav-item">
              <Link className={`nav-link ${currentPath === '/about' ? 'active' : ''}`} to="/about">About Us</Link>
            </li>
            <li className="nav-item">
              <Link className={`nav-link ${currentPath === '/courses' ? 'active' : ''}`} to="/courses">Courses</Link>
            </li>
            <li className="nav-item">
              <Link className={`nav-link ${currentPath === '/services' ? 'active' : ''}`} to="/services">Services</Link>
            </li>
            <li className="nav-item">
              <Link className={`nav-link ${currentPath === '/deals' ? 'active' : ''}`} to="/deals">Deals/Offers</Link>
            </li>
            <li className="nav-item">
              <Link className={`nav-link btn btn-gradient text-white px-4 ms-lg-3 ${currentPath === '/appointments' ? 'active' : ''}`} to="/appointments">
                Book Appointment
              </Link>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
