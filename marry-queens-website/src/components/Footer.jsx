import { Link } from 'react-router-dom';

const Footer = () => {
  return (
    <footer className="bg-dark text-white pt-5 pb-3 mt-auto">
      <div className="container">
        <div className="row">
          {/* Logo */}
          <div className="col-md-3 footer-logo mb-4">
            <img src="/images/logo.png" alt="logo" style={{ maxHeight: '60px' }} />
            <h5 className="mt-2 fw-bold">Queen's Merry Beauty Saloon</h5>
          </div>

          {/* Address */}
          <div className="col-md-3 mb-4">
            <h5 className="fw-bold text-gradient">Address</h5>
            <p className="mt-3"><i className="bi bi-geo-alt me-2"></i> I-8 Markaz Islamabad</p>
          </div>

          {/* Policies */}
          <div className="col-md-3 mb-4">
            <h5 className="fw-bold text-gradient">Policies</h5>
            <div className="d-flex flex-column gap-2 mt-3">
              <Link to="/terms" className="text-white opacity-75 text-decoration-none hover-opacity-100 italic">Terms & Conditions</Link>
              <Link to="/privacy" className="text-white opacity-75 text-decoration-none hover-opacity-100 italic">Privacy Policy</Link>
              <Link to="/refund-policy" className="text-white opacity-75 text-decoration-none hover-opacity-100 italic">Refund Policy</Link>
            </div>
          </div>

          {/* Contact + Social */}
          <div className="col-md-3 mb-4">
            <h5 className="fw-bold text-gradient">Contact</h5>
            <p className="mt-3 overflow-hidden text-nowrap"><i className="bi bi-telephone me-2"></i> +92-308-5494369</p>
            <p className="overflow-hidden text-nowrap"><i className="bi bi-envelope me-2"></i> info@queensmarry.com</p>

            <h5 className="fw-bold text-gradient mt-4">Connect With Us</h5>
            <div className="app-buttons d-flex gap-2 mt-3">
              <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Google Play" style={{ height: '35px', cursor: 'pointer' }} />
              <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="App Store" style={{ height: '35px', cursor: 'pointer' }} />
            </div>
          </div>
        </div>

        {/* Bottom */}
        <div className="footer-bottom text-center mt-4 pt-4 border-top border-secondary">
          <p className="mb-0 text-secondary">Copyright ©2026 Queen's Merry Beauty Saloon. All Rights Reserved</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
