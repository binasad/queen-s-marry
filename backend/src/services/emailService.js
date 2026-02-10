const nodemailer = require('nodemailer');
require('dotenv').config();

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransporter({
      host: process.env.EMAIL_HOST,
      port: process.env.EMAIL_PORT,
      secure: false,
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
      },
    });
  }

  async sendVerificationEmail(email, token, name) {
    const verificationUrl = `${process.env.FRONTEND_URL}/verify-email/${token}`;

    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Verify Your Email - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; padding: 15px 30px; background: #FF6CBF; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to Salon App!</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>Thank you for registering with Salon App. To complete your registration, please verify your email address by clicking the button below:</p>
              <div style="text-align: center;">
                <a href="${verificationUrl}" class="button">Verify Email Address</a>
              </div>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
              <p>This link will expire in 24 hours.</p>
              <p>If you didn't create this account, please ignore this email.</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Verification email sent to:', email);
    } catch (error) {
      console.error('Error sending verification email:', error);
      throw error;
    }
  }

  async sendOTPEmail(email, otp, name) {
    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Your Email Verification Code - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .otp-box { 
              background: #fff;
              border: 2px solid #FF6CBF;
              padding: 20px;
              text-align: center;
              border-radius: 8px;
              margin: 20px 0;
              font-size: 32px;
              font-weight: bold;
              color: #FF6CBF;
              letter-spacing: 5px;
              font-family: monospace;
            }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .note { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Verify Your Email</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>Thank you for registering with Salon App. To complete your registration, please enter the verification code below:</p>
              <div class="otp-box">${otp}</div>
              <p style="text-align: center; color: #666;">This code will expire in 15 minutes</p>
              <div class="note">
                <strong>⚠ Security Note:</strong> Never share this code with anyone. Salon App staff will never ask for your verification code.
              </div>
              <p>If you didn't create this account, please ignore this email.</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('OTP email sent to:', email);
    } catch (error) {
      console.error('Error sending OTP email:', error);
      throw error;
    }
  }

  async sendPasswordResetEmail(email, token, name) {
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${token}`;

    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Reset Your Password - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .button { display: inline-block; padding: 15px 30px; background: #FF6CBF; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Password Reset Request</h1>
            </div>
            <div class="content">
              <p>Hi ${name},</p>
              <p>We received a request to reset your password for your Salon App account. Click the button below to reset it:</p>
              <div style="text-align: center;">
                <a href="${resetUrl}" class="button">Reset Password</a>
              </div>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break: break-all; color: #666;">${resetUrl}</p>
              <div class="warning">
                <strong>⚠️ Security Notice:</strong> This link will expire in 1 hour. If you didn't request a password reset, please ignore this email and your password will remain unchanged.
              </div>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Password reset email sent to:', email);
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw error;
    }
  }

  async sendAppointmentConfirmation(email, appointmentDetails) {
    const { customerName, serviceName, date, time, price } = appointmentDetails;

    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Appointment Confirmation - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #FF6CBF, #FF8FD8); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .details { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }
            .detail-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>✓ Appointment Confirmed!</h1>
            </div>
            <div class="content">
              <p>Hi ${customerName},</p>
              <p>Your appointment has been confirmed. Here are the details:</p>
              <div class="details">
                <div class="detail-row">
                  <strong>Service:</strong>
                  <span>${serviceName}</span>
                </div>
                <div class="detail-row">
                  <strong>Date:</strong>
                  <span>${date}</span>
                </div>
                <div class="detail-row">
                  <strong>Time:</strong>
                  <span>${time}</span>
                </div>
                <div class="detail-row">
                  <strong>Price:</strong>
                  <span>Rs. ${price}</span>
                </div>
              </div>
              <p>We look forward to seeing you!</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Appointment confirmation email sent to:', email);
    } catch (error) {
      console.error('Error sending appointment confirmation email:', error);
      throw error;
    }
  }

  async sendAppointmentReminder(email, appointmentDetails) {
    const { customerName, serviceName, date, time } = appointmentDetails;

    const mailOptions = {
      from: process.env.EMAIL_FROM,
      to: email,
      subject: 'Appointment Reminder - Salon App',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #4CAF50, #81C784); padding: 30px; text-align: center; color: white; border-radius: 10px 10px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
            .details { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>⏰ Appointment Reminder</h1>
            </div>
            <div class="content">
              <p>Hi ${customerName},</p>
              <p>This is a friendly reminder about your upcoming appointment:</p>
              <div class="details">
                <h2>${serviceName}</h2>
                <p><strong>${date}</strong> at <strong>${time}</strong></p>
              </div>
              <p>We look forward to seeing you!</p>
              <p>Best regards,<br>Salon App Team</p>
            </div>
            <div class="footer">
              <p>© 2026 Salon App. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log('Appointment reminder email sent to:', email);
    } catch (error) {
      console.error('Error sending appointment reminder email:', error);
      throw error;
    }
  }
}

module.exports = new EmailService();
