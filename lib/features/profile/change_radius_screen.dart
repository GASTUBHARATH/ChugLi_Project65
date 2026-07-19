import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chugli_project65/features/profile/about_radius_screen.dart';
import 'package:chugli_project65/data/services/activity_data_service.dart';
import 'package:chugli_project65/data/services/firestore_room_service.dart';
import 'package:chugli_project65/data/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class ChangeRadiusScreen extends StatefulWidget {
  const ChangeRadiusScreen({super.key});

  @override
  State<ChangeRadiusScreen> createState() => _ChangeRadiusScreenState();
}

class _ChangeRadiusScreenState extends State<ChangeRadiusScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRadius = '0.5 km';
  final List<String> _radiusOptions = ['0.5 km', '1 km', '2 km', '5 km'];
  late AnimationController _pulseController;

  bool _isLoadingRooms = true;
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _nearbyRooms = [];
  double? _userLat;
  double? _userLon;
  String _locationStatus = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadInitialRadius();
    _fetchLocationAndRooms();
  }

  Future<void> _loadInitialRadius() async {
    final prefs = await SharedPreferences.getInstance();
    String saved = prefs.getString('selected_radius') ?? '0.5 km';
    // Normalize old format '0.5km' -> '0.5 km'
    if (!saved.contains(' ')) saved = saved.replaceFirst('km', ' km');
    if (mounted) {
      setState(() => _selectedRadius = saved);
    }
  }

  Future<void> _fetchLocationAndRooms() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Getting your location…';
    });

    // Try to use already-cached location first
    final cached = LocationService.instance.latitude;
    if (cached != null) {
      _userLat = cached;
      _userLon = LocationService.instance.longitude;
    } else {
      final result = await LocationService.instance.getCurrentLocation();
      if (result.isGranted && result.position != null) {
        _userLat = result.position!.latitude;
        _userLon = result.position!.longitude;
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _isLoadingRooms = false;
            _locationStatus = 'Location unavailable. Enable location to see nearby rooms.';
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        _locationStatus = 'Fetching nearby rooms…';
        _isLoadingRooms = true;
      });
    }

    await _loadNearbyRooms();
  }

  Future<void> _loadNearbyRooms() async {
    if (_userLat == null || _userLon == null) return;

    setState(() => _isLoadingRooms = true);

    try {
      final double maxKm =
          double.tryParse(_selectedRadius.replaceAll(' km', '')) ?? 0.5;

      // Fetch all active rooms from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final now = DateTime.now();
      final List<Map<String, dynamic>> rooms = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Parse expiry
        final expiresAt = data['expiresAt'] is Timestamp
            ? (data['expiresAt'] as Timestamp).toDate()
            : now.subtract(const Duration(seconds: 1));
        if (!expiresAt.isAfter(now)) continue; // skip expired rooms

        // Calculate real distance if room has location
        double? distKm;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          distKm = Geolocator.distanceBetween(
                _userLat!, _userLon!, lat, lon) /
              1000.0;
        }

        // Apply radius filter
        final roomRadius = (data['roomRadius'] as num?)?.toDouble() ?? 0.5;
        if (distKm != null && (distKm > maxKm || distKm > roomRadius)) continue;

        data['_distanceKm'] = distKm;
        final uids = List<String>.from(data['participantUids'] ?? []);
        data['participants'] = uids.isEmpty ? 1 : uids.length;
        rooms.add(data);
      }

      // Sort by distance ascending (rooms without location go to the end)
      rooms.sort((a, b) {
        final da = a['_distanceKm'] as double?;
        final db = b['_distanceKm'] as double?;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      if (mounted) {
        setState(() {
          _nearbyRooms = rooms;
          _isLoadingRooms = false;
          _locationStatus = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRooms = false;
          _locationStatus = 'Could not load rooms: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _applyRadius() async {
    final prefs = await SharedPreferences.getInstance();
    // Save in the format used by the home feed
    final feedFormat = _selectedRadius.replaceAll(' ', '');
    await prefs.setString('selected_radius', feedFormat);

    ActivityDataService.instance.addActivity(
      title: 'Radius Changed',
      type: 'System',
      action: 'Radius Updated',
      preview: 'New radius: $_selectedRadius',
    );

    FirestoreRoomService.instance.syncUserLocationAndNotifications();

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6C47FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Radius',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutRadiusScreen()));
            },
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(),
                const SizedBox(height: 24),
                _buildRadiusSelector(),
                const SizedBox(height: 24),
                _buildRadiusVisualization(),
                const SizedBox(height: 24),
                _buildPrivacyCard(),
                const SizedBox(height: 24),
                _buildNearbyRoomPreview(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _applyRadius,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Radius',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF6C47FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "See conversations happening around you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "We only use approximate location to show nearby rooms.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: _radiusOptions.map((option) {
          bool isSelected = _selectedRadius == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedRadius = option);
                _loadNearbyRooms();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF6C47FF)
                        : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRadiusVisualization() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140 + (_pulseController.value * 20),
                    height: 140 + (_pulseController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C47FF).withValues(alpha: 0.05),
                    ),
                  ),
                  Container(
                    width: 100 + (_pulseController.value * 10),
                    height: 100 + (_pulseController.value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF6C47FF),
                    ),
                    child: Center(
                      child: Text(
                        _selectedRadius.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 20,
                    right: 40,
                    child: Icon(Icons.location_on,
                        color: Color(0xFFFF7A59), size: 24),
                  ),
                  const Positioned(
                    bottom: 30,
                    left: 50,
                    child:
                        Icon(Icons.person, color: Color(0xFF00C48C), size: 20),
                  ),
                ],
              );
            },
          ),
        ),
        Text(
          'Discover conversations within $_selectedRadius',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingRooms)
          const SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6C47FF),
            ),
          )
        else
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_nearbyRooms.length} Active Room${_nearbyRooms.length != 1 ? 's' : ''} Nearby',
              style: const TextStyle(
                color: Color(0xFF6C47FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6C47FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy First',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your exact location is never shared. Only approximate distance is used to show nearby rooms.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyRoomPreview() {
    if (_isLoadingLocation) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C47FF)),
              const SizedBox(height: 12),
              Text(
                _locationStatus,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_locationStatus.isNotEmpty && !_isLoadingRooms) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off_outlined,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _locationStatus,
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyRooms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.explore_off_outlined,
                  size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No active rooms within $_selectedRadius',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Try increasing your radius to discover more conversations.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final displayRooms =
        _nearbyRooms.length > 3 ? _nearbyRooms.sublist(0, 3) : _nearbyRooms;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Nearby Rooms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_nearbyRooms.length}',
                  style: const TextStyle(
                    color: Color(0xFF6C47FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayRooms.length,
            itemBuilder: (context, index) {
              final room = displayRooms[index];
              final double? distKm = room['_distanceKm'] as double?;
              final String title =
                  room['title'] as String? ?? 'Unnamed Room';
              final int participants = room['participants'] as int? ?? 1;
              final String category =
                  room['category'] as String? ?? 'General';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF6C47FF).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF6C47FF), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '$participants ${participants == 1 ? 'person' : 'people'}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C47FF)
                                      .withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6C47FF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (distKm != null)
                          Text(
                            '${distKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C47FF),
                            ),
                          )
                        else
                          const Text(
                            'Nearby',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C47FF),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (_nearbyRooms.length > 3)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '+${_nearbyRooms.length - 3} more rooms within $_selectedRadius',
                  style: const TextStyle(
                    color: Color(0xFF6C47FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
