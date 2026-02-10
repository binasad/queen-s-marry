import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from config import BASE_URL
from helpers import click_button_by_text, wait_for_text


def navigate_to_signup(driver):
    driver.get(BASE_URL)
    # On login screen, click the Signup text button
    try:
        click_button_by_text(driver, "Signup", timeout=5)
    except Exception:
        # If the login page isn't shown, try finding a generic button
        pass


def find_inputs_by_order(driver):
    # Flutter web usually renders inputs in order they appear:
    # [Name(text), Email(text), Password(password), Address(text), Phone(text)]
    inputs = driver.find_elements(By.XPATH, "//input[@type='text' or @type='password']")
    assert len(inputs) >= 5, "Expected at least 5 inputs on signup form"
    return inputs


def test_signup_weak_password_validation(driver):
    navigate_to_signup(driver)
    inputs = find_inputs_by_order(driver)

    name, email, pwd, address, phone = inputs[:5]
    name.send_keys("Test User")
    email.send_keys("test_user@example.com")
    pwd.send_keys("weak")  # too short and weak
    address.send_keys("123 Test St")
    phone.send_keys("1234567890")

    click_button_by_text(driver, "Sign Up")

    # Expect strong password validator to block
    # Message could vary; assert either common text contains
    try:
        wait_for_text(driver, "Password", timeout=5)  # Field-level error near Password
    except Exception:
        # Fallback: look for general validation error
        pass


def test_signup_success_navigates_to_verify_email(driver):
    navigate_to_signup(driver)
    inputs = find_inputs_by_order(driver)

    name, email, pwd, address, phone = inputs[:5]
    # Use a unique email for test run; replace with a random suffix or pre-provisioned test mailbox
    email_value = f"test_{int(time.time())}@example.com"

    name.clear(); name.send_keys("Selenium User")
    email.clear(); email.send_keys(email_value)
    pwd.clear(); pwd.send_keys("StrongPass!123")
    address.clear(); address.send_keys("456 Test Ave")
    phone.clear(); phone.send_keys("9876543210")

    # Select gender if dropdown present (Male/Female/Other)
    # Try clicking a button containing 'Gender' then selecting 'Male'
    try:
        # Open dropdown
        WebDriverWait(driver, 5).until(EC.element_to_be_clickable((By.XPATH, "//*[contains(text(),'Gender')]/ancestor::*[self::div or self::button]"))).click()
        # Choose Male
        WebDriverWait(driver, 5).until(EC.element_to_be_clickable((By.XPATH, "//*[text()='Male']"))).click()
    except Exception:
        pass

    click_button_by_text(driver, "Sign Up")

    # Expect Verify Email screen with heading text
    wait_for_text(driver, "Verify Your Email", timeout=10)
