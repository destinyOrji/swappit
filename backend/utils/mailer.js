const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.EMAIL_PORT) || 465,
  secure: true,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendOTPEmail = async (to, name, otp) => {
  const mailOptions = {
    from: `"Swappit" <${process.env.EMAIL_USER}>`,
    to,
    subject: 'Your Swappit Verification Code',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; background: #f5f7fa; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #00BFA6; font-size: 28px; margin: 0;">Swappit</h1>
          <p style="color: #6B7280; margin: 4px 0;">Skill Trading Platform</p>
        </div>
        <div style="background: #ffffff; padding: 24px; border-radius: 8px;">
          <h2 style="color: #1A1A2E; margin-top: 0;">Hi ${name}! 👋</h2>
          <p style="color: #6B7280;">Use the code below to verify your email address. It expires in 10 minutes.</p>
          <div style="text-align: center; margin: 24px 0;">
            <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #00BFA6; background: #f0fdfb; padding: 12px 24px; border-radius: 8px;">${otp}</span>
          </div>
          <p style="color: #9CA3AF; font-size: 12px;">If you didn't create a Swappit account, you can safely ignore this email.</p>
        </div>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

module.exports = { sendOTPEmail };
