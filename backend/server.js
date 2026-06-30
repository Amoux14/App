import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/caresathi';
const port = Number(process.env.PORT || 3000);

mongoose.set('strictQuery', false);

const otpSchema = new mongoose.Schema(
  {
    mobile: { type: String, required: true },
    otp: { type: String, required: true },
    expiresAt: { type: Date, required: true },
  },
  { timestamps: true }
);

const userSchema = new mongoose.Schema(
  {
    mobile: { type: String, required: true, unique: true },
    verified: { type: Boolean, default: false },
  },
  { timestamps: true }
);

const Otp = mongoose.model('Otp', otpSchema);
const User = mongoose.model('User', userSchema);

const bookingSchema = new mongoose.Schema(
  {
    bookingId: { type: String, required: true, unique: true },
    serviceName: { type: String, required: true },
    name: { type: String, required: true },
    address: { type: String, required: true },
    emergencyContact: { type: String, required: true },
    date: { type: String, required: true },
    time: { type: String, required: true },
    gender: { type: String, required: true },
    mobile: { type: String },
    status: { type: String, default: 'confirmed' },
  },
  { timestamps: true }
);

const ticketSchema = new mongoose.Schema(
  {
    bookingId: { type: String, required: true },
    ticketNumber: { type: String, required: true, unique: true },
    serviceName: { type: String, required: true },
    name: { type: String, required: true },
    mobile: { type: String },
    details: { type: String, required: true },
    adminVisible: { type: Boolean, default: true },
  },
  { timestamps: true }
);

const Booking = mongoose.model('Booking', bookingSchema);
const Ticket = mongoose.model('Ticket', ticketSchema);

async function connectMongo() {
  try {
    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('MongoDB connection failed:', error);
    process.exit(1);
  }
}

connectMongo();

const isValidMobile = (mobile) => typeof mobile === 'string' && /^[0-9]{10}$/.test(mobile);
const isValidOtp = (otp) => typeof otp === 'string' && /^[0-9]{4}$/.test(otp);
const generateOtp = () => Math.floor(1000 + Math.random() * 9000).toString();
const generateBookingId = () => `CS-${Date.now()}`;
const generateTicketNumber = () => `TKT-${Math.floor(100000 + Math.random() * 900000)}`;
const adminKey = process.env.ADMIN_KEY || 'admin-secret';

function requireAdmin(req, res, next) {
  const key = req.header('x-admin-key');
  if (!key || key !== adminKey) {
    return res.status(401).json({ message: 'Unauthorized admin access.' });
  }
  next();
}

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/auth/send-otp', async (req, res) => {
  const { mobile } = req.body;

  if (!isValidMobile(mobile)) {
    return res.status(400).json({ message: 'Mobile must be a 10-digit number.' });
  }

  const otp = generateOtp();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

  await Otp.findOneAndUpdate(
    { mobile },
    { mobile, otp, expiresAt },
    { upsert: true, new: true }
  );

  await User.findOneAndUpdate(
    { mobile },
    { mobile, verified: false },
    { upsert: true, new: true }
  );

  console.log(`Generated OTP for ${mobile}: ${otp}`);

  res.json({ message: 'OTP sent successfully.', otp });
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const { mobile, otp } = req.body;

  if (!isValidMobile(mobile) || !isValidOtp(otp)) {
    return res.status(400).json({ message: 'Invalid mobile number or OTP.' });
  }

  const record = await Otp.findOne({ mobile }).sort({ createdAt: -1 });

  if (!record || record.otp !== otp || record.expiresAt < new Date()) {
    return res.status(401).json({ message: 'Invalid or expired OTP.' });
  }

  await User.findOneAndUpdate(
    { mobile },
    { verified: true },
    { upsert: true, new: true }
  );

  await Otp.deleteMany({ mobile });

  res.json({ message: 'OTP verified successfully.' });
});

app.post('/api/bookings', async (req, res) => {
  const { serviceName, name, address, emergencyContact, date, time, gender, mobile } = req.body;

  if (
    !serviceName ||
    !name ||
    !address ||
    !emergencyContact ||
    !date ||
    !time ||
    !gender
  ) {
    return res.status(400).json({ message: 'All booking fields are required.' });
  }

  if (!isValidMobile(emergencyContact)) {
    return res.status(400).json({ message: 'Emergency contact must be a 10-digit number.' });
  }

  const bookingId = generateBookingId();
  const ticketNumber = generateTicketNumber();

  await Booking.create({
    bookingId,
    serviceName,
    name,
    address,
    emergencyContact,
    date,
    time,
    gender,
    mobile,
  });

  await Ticket.create({
    bookingId,
    ticketNumber,
    serviceName,
    name,
    mobile,
    details: `Booking for ${serviceName} on ${date} at ${time}`,
  });

  res.json({
    message: 'Booking confirmed and ticket generated for admin.',
    bookingId,
  });
});

app.get('/api/admin/tickets', requireAdmin, async (_req, res) => {
  const tickets = await Ticket.find({ adminVisible: true }).sort({ createdAt: -1 });
  res.json({ tickets });
});

app.get('/api/admin/tickets/:ticketNumber', requireAdmin, async (req, res) => {
  const ticket = await Ticket.findOne({ ticketNumber: req.params.ticketNumber, adminVisible: true });
  if (!ticket) {
    return res.status(404).json({ message: 'Ticket not found.' });
  }
  res.json({ ticket });
});

app.listen(port, () => {
  console.log(`Backend listening on http://127.0.0.1:${port}`);
});
