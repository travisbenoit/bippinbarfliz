import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  int _currentStep = 0;
  bool _locationGranted = false;
  bool _locationDenied = false;
  bool _cameraGranted = false;
  bool _notificationGranted = false;

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    setState(() {
      _locationGranted = status.isGranted;
      _locationDenied = status.isDenied || status.isPermanentlyDenied;
      if (_locationGranted) {
        _currentStep = 1;
      }
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraGranted = status.isGranted;
      _currentStep = 2;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationGranted = status.isGranted;
    });
    _continue();
  }

  void _skipLocation() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _skipCamera() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _continue() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_locationDenied && _currentStep == 0) {
      return _buildLocationDeniedScreen();
    }

    switch (_currentStep) {
      case 0:
        return _buildLocationScreen();
      case 1:
        return _buildCameraScreen();
      case 2:
        return _buildNotificationScreen();
      default:
        return _buildLocationScreen();
    }
  }

  Widget _buildLocationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enable Location to\nConnect in Real Life',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Barfliz uses your location to place you inside real venues so you can meet and interact with others around you in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE91E63).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: const Color(0xFFE91E63).withOpacity(0.7),
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your exact location is never shared publicly. You control who sees you.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFFE91E63).withOpacity(0.4),
                  ),
                  child: const Text(
                    'Allow Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipLocation,
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDeniedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  color: Colors.amber.shade700,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Limited Experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Without location access, you won\'t be able to:\n\n'
                '- Auto check-in to venues\n'
                '- See who\'s nearby\n'
                '- Get venue recommendations\n'
                '- Use real-time social features',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => openAppSettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipLocation,
                child: Text(
                  'Continue Without Location',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enable Camera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Used for profile photos and sharing moments in venues. Show others your best side!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestCameraPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFF2196F3).withOpacity(0.4),
                  ),
                  child: const Text(
                    'Allow Camera',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipCamera,
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Stay in the Loop',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Get notified when friends arrive at venues, when you receive messages, and when swarms are happening nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestNotificationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFFFF9800).withOpacity(0.4),
                  ),
                  child: const Text(
                    'Allow Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _continue,
                child: Text(
                  'Not Now',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
