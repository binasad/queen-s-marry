# Selenium E2E Tests for Salon App (Flutter Web)

These Selenium tests exercise Login and Signup flows in the Flutter web app.

## Prerequisites
- Python 3.10+
- Chrome installed
- Flutter app can run in web mode

## Install Dependencies
```bash
python -m venv .venv
. .venv/Scripts/activate  # Windows PowerShell
pip install -r tests/selenium/requirements.txt
```

## Run the Flutter Web App with a Fixed Port
Use a fixed port so Selenium can reach it.
```bash
flutter run -d chrome --web-port 7357 --dart-define=IS_DEV_MODE=false
```

Note: Keep `IS_DEV_MODE=false` so auth screens are visible for testing.

## Configure Test Credentials
Edit `tests/selenium/config.py`:
- `BASE_URL` must match the port you used (default `http://localhost:7357`).
- `DEV_EMAIL` and `DEV_PASSWORD` should be valid user credentials for the login success test.

## Run Tests
```bash
pytest -q tests/selenium
```

## Locators & Notes
- Flutter web renders `TextFormField` as `<input>`, so tests use `//input[@type='text']` and `//input[@type='password']`.
- Buttons are located by visible text, e.g., `LOGIN`, `Sign Up`, `Signup`.
- Snackbars are checked via visible text contents.
- The Signup success test expects navigation to the Verify Email screen; it asserts heading text `Verify Your Email`.

## Tips
- If the landing page is an onboarding screen, adjust navigation helpers to click through to Login first.
- For unique signup emails, tests append a timestamp to avoid collisions.
- If gender selection fails (dropdown timing), the test continues without failing; selection isn't mandatory for the assertion.
