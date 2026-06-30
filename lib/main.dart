import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const String baseUrl = 'http://127.0.0.1:4000';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: LoginScreen(),
    ));

// ─── SCREEN 1: Enter Mobile Number ───────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  String _error = '';
  bool _loading = false;

  Future<void> _sendOtp() async {
    if (_mobile.text.trim().length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit number');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': _mobile.text.trim()}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              mobile: _mobile.text.trim(),
              debugOtp: data['otp'] ?? '',
            ),
          ),
        );
      } else {
        setState(() => _error = data['message']);
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server. Is it running?');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CareSaathi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
            Text('Senior Citizen Support', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 40),
            Text('Enter your mobile number', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            TextField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                prefixText: '+91 ',
                border: OutlineInputBorder(),
                hintText: '9876543210',
              ),
            ),
            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15)),
                child: _loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCREEN 2: Enter OTP ─────────────────────────────────────────────────────
class OtpScreen extends StatefulWidget {
  final String mobile;
  final String debugOtp;
  const OtpScreen({super.key, required this.mobile, this.debugOtp = ''});
  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  String _error = '';
  bool _loading = false;

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': widget.mobile,
          'otp': _otp.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(mobile: widget.mobile)),
        );
      } else {
        setState(() => _error = data['message']);
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server.');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CareSaathi', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal)),
            SizedBox(height: 40),
            Text('OTP sent to +91 ${widget.mobile}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter 4-digit OTP',
              ),
            ),
            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),
            if (widget.debugOtp.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  'Debug OTP: ${widget.debugOtp}',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15)),
                child: _loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Verify OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCREEN 3: Home Screen ────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final String mobile;
  const HomeScreen({super.key, required this.mobile});

  final List<Map<String, dynamic>> services = const [
    {'icon': Icons.local_hospital,    'title': 'Hospital Visit',        'subtitle': 'Escort to & from hospital'},
    {'icon': Icons.flight,            'title': 'Airport Drop & Pickup', 'subtitle': 'Travel assistance'},
    {'icon': Icons.train,             'title': 'Railway Station',       'subtitle': 'Drop & pickup support'},
    {'icon': Icons.event_seat,        'title': 'Train Seat Assistance', 'subtitle': 'Photo proof included'},
    {'icon': Icons.home,              'title': 'Home Pickup & Drop',    'subtitle': 'Door to door service'},
    {'icon': Icons.directions_bus,    'title': 'Station to Bus Stop',   'subtitle': 'Transfer assistance'},
    {'icon': Icons.access_time,       'title': 'Hourly Personal Care',  'subtitle': 'Dedicated care support'},
    {'icon': Icons.emergency,         'title': 'Emergency Assistance',  'subtitle': 'Immediate help'},
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('CareSaathi'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: Icon(Icons.person), onPressed: () {})
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello! 👋', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text('What help do you need today?',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Our Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Services Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(serviceName: service['title'], mobile: mobile),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(service['icon'], size: 36, color: Colors.teal),
                          SizedBox(height: 8),
                          Text(service['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 4),
                          Text(service['subtitle'],
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCREEN 4: Booking Form ───────────────────────────────────────────────────
class BookingScreen extends StatefulWidget {
  final String serviceName;
  final String mobile;
  const BookingScreen({super.key, required this.serviceName, required this.mobile});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _emergency = TextEditingController();
  String _gender = 'No Preference';
  String _selectedDate = '';
  String _selectedTime = '';
  String _error = '';
  bool _loading = false;

  final List<String> _timeSlots = [
    '9:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '2:00 PM', '3:00 PM',
    '4:00 PM', '5:00 PM'
  ];

  // Pick a date
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_name.text.isEmpty ||
        _address.text.isEmpty ||
        _emergency.text.isEmpty ||
        _selectedDate.isEmpty ||
        _selectedTime.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'serviceName': widget.serviceName,
          'name': _name.text.trim(),
          'address': _address.text.trim(),
          'emergencyContact': _emergency.text.trim(),
          'date': _selectedDate,
          'time': _selectedTime,
          'gender': _gender,
          'mobile': widget.mobile,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              serviceName: widget.serviceName,
              name: _name.text,
              address: _address.text,
              date: _selectedDate,
              time: _selectedTime,
              gender: _gender,
              bookingId: data['bookingId'] ?? 'Unavailable',
              mobile: widget.mobile,
            ),
          ),
        );
      } else {
        setState(() => _error = data['message'] ?? 'Booking failed.');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server. Is it running?');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Name
            Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                hintText: 'Enter senior citizen\'s name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Address
            Text('Pickup Address', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            TextField(
              controller: _address,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter full address',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Emergency Contact
            Text('Emergency Contact Number', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            TextField(
              controller: _emergency,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: 'Family member\'s number',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Date Picker
            Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedDate.isEmpty ? 'Tap to select date' : _selectedDate,
                  style: TextStyle(
                    color: _selectedDate.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Time Slot
            Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTime == slot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = slot),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white,
                      border: Border.all(color: Colors.teal),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),

            // Gender Preference
            Text('Helper Gender Preference', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _gender,
                  isExpanded: true,
                  items: ['No Preference', 'Male', 'Female']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _gender = val!),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Error
            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.all(16),
                ),
                child: _loading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Confirm Booking', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SCREEN 5: Booking Confirmation ──────────────────────────────────────────
class ConfirmationScreen extends StatelessWidget {
  final String serviceName;
  final String name;
  final String address;
  final String date;
  final String time;
  final String gender;
  final String bookingId;
  final String mobile;

  const ConfirmationScreen({super.key,
    required this.serviceName,
    required this.name,
    required this.address,
    required this.date,
    required this.time,
    required this.gender,
    required this.bookingId,
    required this.mobile,
  });

  // Hardcoded provider details (in real app this comes from backend)
  final String providerName = 'Suresh Kumar';
  final String providerPhone = '9876543210';
  final String providerRating = '4.8 ⭐';
  final String price = '₹ 499';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Booking Confirmed'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            // Success Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 60),
                  SizedBox(height: 10),
                  Text('Booking Confirmed!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Booking ID: $bookingId',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Booking Details Card
            _card(
              title: 'Booking Details',
              children: [
                _row(Icons.design_services, 'Service', serviceName),
                _row(Icons.person, 'Name', name),
                _row(Icons.location_on, 'Address', address),
                _row(Icons.calendar_today, 'Date', date),
                _row(Icons.access_time, 'Time', time),
                _row(Icons.wc, 'Helper Gender', gender),
                _row(Icons.currency_rupee, 'Amount', price),
              ],
            ),
            SizedBox(height: 16),

            // Provider Details Card
            _card(
              title: 'Your Helper',
              children: [
                _row(Icons.person_pin, 'Name', providerName),
                _row(Icons.phone, 'Contact', providerPhone),
                _row(Icons.star, 'Rating', providerRating),
              ],
            ),
            SizedBox(height: 16),

            // Status Card
            _card(
              title: 'Booking Status',
              children: [
                Row(
                  children: [
                    _statusDot(Colors.teal),
                    Text('Confirmed', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your helper will arrive at the selected time. You will receive an SMS confirmation shortly.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Track Button → Stage 5
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.location_on),
                label: Text('Track Helper (Coming Stage 5)', style: TextStyle(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.all(16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TrackingScreen(providerName: providerName)),
                  );
                },
              ),
            ),
            SizedBox(height: 12),

            // Back to Home Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.home, color: Colors.teal),
                label: Text('Back to Home', style: TextStyle(color: Colors.teal, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  side: BorderSide(color: Colors.teal),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen(mobile: mobile)),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────
  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _statusDot(Color color) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── SCREEN 6: GPS Tracking Screen ───────────────────────────────────────────
class TrackingScreen extends StatefulWidget {
  final String providerName;
  const TrackingScreen({super.key, required this.providerName});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Simulated provider starting location (Pune)
  double _providerLat = 18.5204;
  double _providerLng = 73.8567;

  // Receiver fixed location
  final double _receiverLat = 18.5314;
  final double _receiverLng = 73.8446;

  String _status = 'Helper is on the way...';
  int _eta = 12; // minutes
  late Timer _timer;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startSimulation();
  }

  // Simulates provider moving toward receiver every 2 seconds
  void _startSimulation() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        // Move provider slowly toward receiver
        _providerLat += (_receiverLat - _providerLat) * 0.1;
        _providerLng += (_receiverLng - _providerLng) * 0.1;

        // Reduce ETA
        if (_eta > 1) {
          _eta--;
          _status = 'Helper is on the way...';
        } else {
          _status = '✅ Helper has arrived!';
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Track Helper'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [

          // Status Bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.teal,
            child: Column(
              children: [
                Text(_status,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                if (_eta > 1)
                  Text('ETA: $_eta minutes',
                      style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_receiverLat, _receiverLng),
                initialZoom: 14,
              ),
              children: [
                // Map tiles (OpenStreetMap - free)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.caresaathi',
                ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Provider marker (moving)
                    Marker(
                      point: LatLng(_providerLat, _providerLng),
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Icon(Icons.directions_walk, color: Colors.blue, size: 30),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Helper',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),

                    // Receiver marker (fixed)
                    Marker(
                      point: LatLng(_receiverLat, _receiverLng),
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Icon(Icons.home, color: Colors.red, size: 30),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('You',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Info Card
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.providerName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Your assigned helper',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Spacer(),
                    // Call Button
                    CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.phone, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // SOS Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.emergency),
                    label: Text('SOS - Emergency', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.all(14),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('🚨 SOS Activated'),
                          content: Text(
                              'Emergency alert sent to your family and CareSaathi support team.'),
                          actions: [
                            TextButton(
                              child: Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}