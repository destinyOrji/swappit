console.log('NODE_ENV:', process.env.NODE_ENV);
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const db = require('../config/db');
const { sendOTPEmail } = require('../utils/mailer');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Generate 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// In-memory OTP store (use Redis in production)
const otpStore = new Map();
const fallbackUsers = [];

const normalizeEmail = (email) => String(email || '').trim().toLowerCase();

const shouldUseDatabase = async () => {
  try {
    await db.execute('SELECT 1');
    return true;
  } catch (err) {
    return false;
  }
};

const getFallbackUserByEmail = (email) => {
  const normalizedEmailValue = normalizeEmail(email);
  return fallbackUsers.find((user) => normalizeEmail(user.email) === normalizedEmailValue);
};

const createFallbackUser = ({ name, email, phone, password }) => {
  const user = {
    id: fallbackUsers.length + 1001,
    name,
    email: normalizeEmail(email),
    phone: phone || null,
    password,
    photo_url: null,
    bio: null,
    location: null,
    rating: 4.0,
    completed_tasks: 0,
    pending_tasks: 0,
    verified: false,
    created_at: new Date(),
  };
  fallbackUsers.push(user);
  return user;
};

// ─── Sign Up ─────────────────────────────────────────────
const signup = async (req, res) => {
  const { name, email, phone, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ success: false, message: 'Name, email and password are required' });
  }

  try {
    const useDatabase = await shouldUseDatabase();

    if (!useDatabase) {
      const existingUser = getFallbackUserByEmail(email);
      if (existingUser) {
        return res.status(409).json({ success: false, message: 'Email already registered' });
      }

      const hashed = await bcrypt.hash(password, 12);
      const fallbackUser = createFallbackUser({ name, email, phone, password: hashed });
      const otp = generateOTP();
      otpStore.set(normalizeEmail(email), { otp, expires: Date.now() + 10 * 60 * 1000 });

      console.warn('Using in-memory fallback auth store because MySQL is unavailable.');
      return res.status(201).json({
        success: true,
        message: 'Account created. OTP sent to your email.',
        userId: fallbackUser.id,
      });
    }

    // Check duplicate email
    const [existing] = await db.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const hashed = await bcrypt.hash(password, 12);
    const [result] = await db.execute(
      'INSERT INTO users (name, email, phone, password) VALUES (?, ?, ?, ?)',
      [name, email, phone || null, hashed]
    );

    // Generate and send OTP
    const otp = generateOTP();
    otpStore.set(email, { otp, expires: Date.now() + 10 * 60 * 1000 }); // 10 min

    if (process.env.NODE_ENV === 'production') {
      await sendOTPEmail(email, name, otp);
    } else {
      console.log(`DEV MODE — OTP for ${email}: ${otp}`);
    }

    return res.status(201).json({
      success: true,
      message: 'Account created. OTP sent to your email.',
      userId: result.insertId,
    });
  } catch (err) {
    console.error('Signup error:', err);
    const message = err && err.code === 'ER_ACCESS_DENIED_ERROR'
      ? 'Database credentials are invalid. Please verify the MySQL user and password.'
      : err && err.code === 'ECONNREFUSED'
        ? 'Database server is not reachable. Please start MySQL and confirm the host/port.'
        : 'Server error during signup';
    return res.status(500).json({ success: false, message });
  }
};

// ─── Verify OTP ──────────────────────────────────────────
const verifyOTP = async (req, res) => {
  const { email, otp } = req.body;

  const normalizedEmail = normalizeEmail(email);
  const record = otpStore.get(normalizedEmail);
  if (!record) {
    return res.status(400).json({ success: false, message: 'No OTP requested for this email' });
  }
  if (Date.now() > record.expires) {
    otpStore.delete(normalizedEmail);
    return res.status(400).json({ success: false, message: 'OTP expired. Please request a new one.' });
  }
  if (record.otp !== otp) {
    return res.status(400).json({ success: false, message: 'Invalid OTP' });
  }

  otpStore.delete(normalizedEmail);

  const useDatabase = await shouldUseDatabase();
  let user;

  if (!useDatabase) {
    user = getFallbackUserByEmail(email);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    user.verified = true;
  } else {
    await db.execute('UPDATE users SET verified = TRUE WHERE email = ?', [email]);
    const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    user = rows[0];
  }

  const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

  return res.json({
    success: true,
    message: 'Email verified successfully',
    token,
    user: sanitizeUser(user),
  });
};

// ─── Resend OTP ──────────────────────────────────────────
const resendOTP = async (req, res) => {
  const { email } = req.body;
  const useDatabase = await shouldUseDatabase();

  if (!useDatabase) {
    const fallbackUser = getFallbackUserByEmail(email);
    if (!fallbackUser) {
      return res.status(404).json({ success: false, message: 'Email not found' });
    }

    const otp = generateOTP();
    otpStore.set(normalizeEmail(email), { otp, expires: Date.now() + 10 * 60 * 1000 });
    console.log(`DEV MODE — OTP for ${email}: ${otp}`);
    return res.json({ success: true, message: 'OTP resent successfully' });
  }

  const [rows] = await db.execute('SELECT name FROM users WHERE email = ?', [email]);
  if (!rows.length) {
    return res.status(404).json({ success: false, message: 'Email not found' });
  }

  const otp = generateOTP();
  otpStore.set(email, { otp, expires: Date.now() + 10 * 60 * 1000 });

  if (process.env.NODE_ENV === 'production') {
    await sendOTPEmail(email, rows[0].name, otp);
  } else {
    console.log(`DEV MODE — OTP for ${email}: ${otp}`);
  }

  return res.json({ success: true, message: 'OTP resent successfully' });
};

// ─── Login ───────────────────────────────────────────────
const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Email and password required' });
  }

  try {
    const useDatabase = await shouldUseDatabase();

    if (!useDatabase) {
      const fallbackUser = getFallbackUserByEmail(email);
      if (!fallbackUser) {
        return res.status(401).json({ success: false, message: 'Invalid email or password' });
      }

      const match = await bcrypt.compare(password, fallbackUser.password);
      if (!match) {
        return res.status(401).json({ success: false, message: 'Invalid email or password' });
      }

      const token = jwt.sign({ id: fallbackUser.id, email: fallbackUser.email }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      });

      return res.json({
        success: true,
        message: 'Login successful',
        token,
        user: sanitizeUser(fallbackUser),
        isProfileComplete: !!(fallbackUser.bio && fallbackUser.location),
      });
    }

    const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (!rows.length) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    return res.json({
      success: true,
      message: 'Login successful',
      token,
      user: sanitizeUser(user),
      isProfileComplete: !!(user.bio && user.location),
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ success: false, message: 'Server error during login' });
  }
};

// ─── Google Sign-In ──────────────────────────────────────
const googleSignIn = async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ success: false, message: 'Google ID token required' });
  }

  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { email, name, picture, sub: googleId } = payload;

    const useDatabase = await shouldUseDatabase();
    let [rows] = [];
    let user;
    let isNewUser = false;

    if (!useDatabase) {
      user = getFallbackUserByEmail(email);
      if (!user) {
        user = createFallbackUser({
          name,
          email,
          phone: null,
          password: bcrypt.hashSync(googleId, 10),
        });
        user.photo_url = picture || null;
        user.verified = true;
        isNewUser = true;
      } else if (!user.photo_url && picture) {
        user.photo_url = picture;
      }
    } else {
      [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
      if (rows.length) {
        user = rows[0];
        // Update photo if not set
        if (!user.photo_url && picture) {
          await db.execute('UPDATE users SET photo_url = ? WHERE id = ?', [picture, user.id]);
          user.photo_url = picture;
        }
      } else {
        // Create new user from Google
        const [result] = await db.execute(
          `INSERT INTO users (name, email, photo_url, password, verified) VALUES (?, ?, ?, ?, TRUE)`,
          [name, email, picture || null, bcrypt.hashSync(googleId, 10)]
        );
        const [newRows] = await db.execute('SELECT * FROM users WHERE id = ?', [result.insertId]);
        user = newRows[0];
        isNewUser = true;
      }
    }

    const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });

    return res.json({
      success: true,
      message: isNewUser ? 'Account created via Google' : 'Login successful',
      token,
      user: sanitizeUser(user),
      isNewUser,
      isProfileComplete: !!(user.bio && user.location),
    });
  } catch (err) {
    console.error('Google sign-in error:', err);
    return res.status(401).json({ success: false, message: 'Invalid Google token' });
  }
};

// ─── Helper ──────────────────────────────────────────────
const sanitizeUser = (user) => ({
  id: user.id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  photo_url: user.photo_url,
  bio: user.bio,
  location: user.location,
  rating: user.rating,
  completed_tasks: user.completed_tasks,
  pending_tasks: user.pending_tasks,
  verified: user.verified,
  created_at: user.created_at,
});

module.exports = { signup, verifyOTP, resendOTP, login, googleSignIn };
