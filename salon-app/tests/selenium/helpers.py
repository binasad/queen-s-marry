from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def wait_for_text(driver, text, timeout=10):
    return WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.XPATH, f"//*[contains(text(), '{text}')]"))
    )


def find_email_input(driver, timeout=10):
    # Flutter web renders TextFormField as input[type=text]
    return WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.XPATH, "//input[@type='text']"))
    )


def find_password_input(driver, timeout=10):
    return WebDriverWait(driver, timeout).until(
        EC.presence_of_element_located((By.XPATH, "//input[@type='password']"))
    )


def click_button_by_text(driver, label, timeout=10):
    # Try common structures: span/div inside a button
    button = WebDriverWait(driver, timeout).until(
        EC.element_to_be_clickable((By.XPATH, f"//button[.//*[contains(text(), '{label}')]]|//span[contains(text(), '{label}')]/ancestor::button"))
    )
    button.click()
    return button
