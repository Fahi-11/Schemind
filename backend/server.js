import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const app = express();

// Fix __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ✅ Use environment PORT or fallback
const PORT = process.env.PORT || 3000;

const MONGO_URI = process.env.MONGO_URI;
const JWT_SECRET = process.env.JWT_SECRET;

// MongoDB connection
mongoose.connect(MONGO_URI)
  .then(() => console.log("✅ MongoDB Connected"))
  .catch(err => console.error("❌ DB Connection Error:", err));

// Schema
const UserSchema = new mongoose.Schema({
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  name: { type: String },
  phoneNumber: { type: String },
  notificationPreferences: {
    enabled: { type: Boolean, default: false },
    time: { type: String },
    message: { type: String }
  },
  currentTopic: { type: String },
  lastStudyDate: { type: Date },
  streak: { type: Number, default: 0 }
});

const User = mongoose.model("User", UserSchema);

// Middleware
app.use(express.json());
app.use(cors());

// ✅ Serve frontend build
app.use(express.static(path.join(__dirname, 'public')));

// ---------------- AUTH ROUTES ----------------

// Signup
app.post("/api/auth/signup", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "All fields are required." });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: "User already exists." });

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({ email, password: hashedPassword });

    await newUser.save();

    res.status(201).json({ message: "✅ User registered successfully." });

  } catch (error) {
    console.error("❌ Signup Error:", error);
    res.status(500).json({ message: "Internal server error." });
  }
});

// Login
app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "All fields are required." });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: "Invalid email or password." });

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(400).json({ message: "Invalid email or password." });

    const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: "1h" });

    res.json({ token });

  } catch (error) {
    console.error("❌ Login Error:", error);
    res.status(500).json({ message: "Internal server error." });
  }
});

// ✅ SPA fallback (VERY IMPORTANT)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});