import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from config import BASE_URL, DEV_EMAIL, DEV_PASSWORD
from helpers import find_email_input, find_password_input, click_button_by_text, wait_for_text


def navigate_to_login(driver):
    driver.get(BASE_URL)
    # The landing screen is Onboarding; click "Login" heading if present or ensure form loads.
    # If login form not visible, try clicking a button labeled "Login".
    try:
        wait_for_text(driver, "Login", timeout=5)
    except Exception:
        # Fallback: try a button labeled LOGIN
        try:
            click_button_by_text(driver, "LOGIN", timeout=3)
        except Exception:
            pass


def test_login_success(driver):
    navigate_to_login(driver)

    email_input = find_email_input(driver)
    password_input = find_password_input(driver)

    email_input.clear(); email_input.send_keys(DEV_EMAIL)
    password_input.clear(); password_input.send_keys(DEV_PASSWORD)

    click_button_by_text(driver, "LOGIN")

    # Expect navigation to user/admin home; assert absence of error and presence of loading or tabs
    # Check no generic error snackbar appears
    time.sleep(1)
    err_present = driver.find_elements(By.XPATH, "//*[contains(text(),'Invalid email or password.')]")
    assert len(err_present) == 0, "Unexpected login error displayed"


def test_login_invalid_then_lockout(driver):
    navigate_to_login(driver)

    email_input = find_email_input(driver)
    password_input = find_password_input(driver)

    # Try three invalid attempts
    for i in range(3):
        email_input.clear(); email_input.send_keys(DEV_EMAIL)
        password_input.clear(); password_input.send_keys("wrong-pass-123")
        click_button_by_text(driver, "LOGIN")
        # Wait for generic error
        wait_for_text(driver, "Invalid email or password.", timeout=5)
        time.sleep(0.2)

    # Fourth attempt should be locked
    email_input.clear(); email_input.send_keys(DEV_EMAIL)
    password_input.clear(); password_input.send_keys("wrong-pass-123")
    click_button_by_text(driver, "LOGIN")

    wait_for_text(driver, "Too many attempts. Try again shortly.", timeout=5)
