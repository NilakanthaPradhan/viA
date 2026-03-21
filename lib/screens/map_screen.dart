import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:via_app/theme/app_theme.dart';
import 'package:via_app/utils/distance_calculator.dart';
import 'package:via_app/services/storage_service.dart';
import 'package:via_app/widgets/stats_panel.dart';
import 'package:animate_do/animate_do.dart';

// ============ MAP PROVIDERS ============
class MapProvider {
  final String name;
  final String icon;
  final String url;
  final List<String> subdomains;
  const MapProvider(this.name, this.icon, this.url,
      [this.subdomains = const []]);
}

const List<MapProvider> _mapProviders = [
  MapProvider('Google Maps', '🌍',
      'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'),
  MapProvider('Google Satellite', '🛰️',
      'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'),
  MapProvider('Google Hybrid', '🌐',
      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'),
  MapProvider('Google Terrain', '⛰️',
      'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}'),
  MapProvider('OpenStreetMap', '🗺️',
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
  MapProvider(
      'CartoDB Voyager',
      '🧭',
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      ['a', 'b', 'c', 'd']),
  MapProvider(
      'CartoDB Dark',
      '🌑',
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
      ['a', 'b', 'c', 'd']),
  MapProvider('OpenTopo', '🏔️',
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', ['a', 'b', 'c']),
];

// ============ MAP SCREEN ============
class MapScreen extends StatefulWidget {
  final List<LatLng>? existingRoute;
  final String? routeName;
  const MapScreen({super.key, this.existingRoute, this.routeName});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _pathPoints = [];
  bool _showStats = false;
  bool _isViewingExisting = false;
  bool _isLocating = false;
  int _selectedProviderIndex = 0;
  LatLng? _userLocation;
  LatLng? _searchMarker;

  // ===== DRAWING STATE =====
  bool _isDrawing = false;
  final Set<int> _activePointers = {};

  // ===== TAP DETECTION =====
  final List<_TapRecord> _tapHistory = [];

  // ===== HINT =====
  bool _showHint = true;

  // Stats
  double _totalDistance = 0;
  int _totalSteps = 0;
  double _totalCalories = 0;
  double _totalDuration = 0;

  // Search debounce
  Timer? _searchDebounce;

  LatLng _initialCenter = const LatLng(20.5937, 78.9629);

  // Live GPS Tracking
  bool _isLiveTracking = false;
  double _currentSpeed = 0.0;
  StreamSubscription<Position>? _positionStream;

  // Weather
  String? _weatherTemp;

  @override
  void initState() {
    super.initState();
    _showHint = !StorageService.hasClosedHint();
    if (widget.existingRoute != null) {
      _isViewingExisting = true;
      _pathPoints.addAll(widget.existingRoute!);
      _updateStats();
      if (widget.existingRoute!.isNotEmpty) {
        _initialCenter = widget.existingRoute!.first;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _getUserLocation());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  // ============ LOCATION ============
  Future<void> _getUserLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      debugPrint('[viA] Checking location...');
      bool serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) {
          _showMsg('⚠️ Location OFF');
          await Geolocator.openLocationSettings();
        }
        if (mounted) setState(() => _isLocating = false);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          if (mounted) {
            _showMsg('❌ Permission denied');
            setState(() => _isLocating = false);
          }
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          _showMsg('❌ Denied — open settings');
          await Geolocator.openAppSettings();
          setState(() => _isLocating = false);
        }
        return;
      }
      Position? last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        _applyLocation(last.latitude, last.longitude);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20)),
      );
      if (mounted) _applyLocation(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('[viA] ERROR: $e');
      if (mounted) {
        setState(() => _isLocating = false);
        _showMsg('📍 Error: $e');
      }
    }
  }

  void _applyLocation(double lat, double lng) {
    final loc = LatLng(lat, lng);
    setState(() {
      _userLocation = loc;
      _isLocating = false;
    });
    _mapController.move(loc, 16.0);
    _showMsg('📍 Located!');
    if (_weatherTemp == null) _fetchWeather(lat, lng);
  }

  void _fetchWeather(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current_weather=true');
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200 && mounted) {
        final data = json.decode(resp.body);
        final temp = data['current_weather']['temperature'];
        final isDay = data['current_weather']['is_day'] == 1;
        setState(() {
          _weatherTemp = '${isDay ? '☀️' : '🌙'} $temp°C';
        });
      }
    } catch (_) {}
  }

  void _centerOnLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 16.0);
    } else {
      _getUserLocation();
    }
  }

  // ============ LIVE TRACKING ============
  Future<void> _toggleLiveTracking() async {
    if (_isLiveTracking) {
      // STOP
      setState(() => _isLiveTracking = false);
      await _positionStream?.cancel();
      _positionStream = null;
      _showMsg('🛑 Journey stopped. You can now save your route.');
    } else {
      // START
      bool serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _showMsg('⚠️ Location is OFF');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      
      setState(() {
        _isLiveTracking = true;
        _showStats = false;
        _pathPoints.clear();
        _totalDistance = 0;
        _totalSteps = 0;
        _totalCalories = 0;
        _totalDuration = 0;
      });
      _showMsg('🚀 Journey started! Walk to track automatically.');
      
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2, 
        ),
      ).listen((Position pos) {
        if (!mounted || !_isLiveTracking) return;
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = loc;
          _currentSpeed = pos.speed * 3.6; // m/s to km/h
          _pathPoints.add(loc);
          _updateStats();
        });
        _mapController.move(loc, _mapController.camera.zoom);
      });
    }
  }

  void _dismissHint() {
    setState(() => _showHint = false);
    StorageService.markHintClosed();
  }

  // ============ SEARCH ============
  Future<void> _showSearchDialog() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          Future<void> doSearch(String query) async {
            if (query.trim().length < 2) return;
            setSheetState(() => searching = true);
            try {
              final uri = Uri.https(
                'nominatim.openstreetmap.org',
                '/search',
                {'q': query, 'format': 'json', 'limit': '8'},
              );
              debugPrint('[viA] Search URL: $uri');
              final resp = await http.get(uri, headers: {
                'User-Agent': 'viA-PathTracker/1.0 (contact@via-app.dev)',
                'Accept': 'application/json',
              });
              debugPrint('[viA] Search status: ${resp.statusCode}');
              debugPrint('[viA] Search body: ${resp.body.substring(0, (resp.body.length < 200) ? resp.body.length : 200)}');
              if (resp.statusCode == 200) {
                final data = json.decode(resp.body) as List;
                setSheetState(() {
                  results = data.map((e) => e as Map<String, dynamic>).toList();
                  searching = false;
                });
              } else {
                setSheetState(() => searching = false);
                if (mounted) _showMsg('Search failed: ${resp.statusCode}');
              }
            } catch (e) {
              debugPrint('[viA] Search error: $e');
              setSheetState(() => searching = false);
              if (mounted) _showMsg('Search error: $e');
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2))),
                ),
                // Search field
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: doSearch,
                  onChanged: (val) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      doSearch(val);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a place...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary)))
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded,
                                color: AppColors.primary),
                            onPressed: () => doSearch(controller.text)),
                    filled: true,
                    fillColor: AppColors.bgDark,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                // Results list
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.35),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (ctx, i) {
                      final r = results[i];
                      final name = r['display_name'] as String? ?? '';
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_rounded,
                            color: AppColors.primary, size: 20),
                        title: Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        onTap: () {
                          final lat = double.tryParse(r['lat'] ?? '');
                          final lon = double.tryParse(r['lon'] ?? '');
                          if (lat != null && lon != null) {
                            final loc = LatLng(lat, lon);
                            setState(() => _searchMarker = loc);
                            _mapController.move(loc, 16.0);
                            Navigator.pop(ctx);
                            _showMsg('📍 $name');
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }

  // ============ GESTURE HANDLERS ============

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);

    // Only process single-finger events for drawing
    if (_activePointers.length != 1) {
      _isDrawing = false;
      return;
    }

    // Record tap for double/triple detection
    _tapHistory.add(_TapRecord(DateTime.now(), event.localPosition));
    // Keep only last 3
    if (_tapHistory.length > 3) {
      _tapHistory.removeAt(0);
    }

    // Check if finger is near the last path point → start drawing
    if (_pathPoints.isNotEmpty && !_isViewingExisting) {
      final lastPt = _pathPoints.last;
      final lastScreen = _mapController.camera.latLngToScreenPoint(lastPt);
      final dx = (event.localPosition.dx - lastScreen.x).abs();
      final dy = (event.localPosition.dy - lastScreen.y).abs();

      if (dx < 70 && dy < 70) {
        // Finger is near the end point — START DRAWING
        setState(() {
          _isDrawing = true;
          _showStats = false; // Hide stats panel when dragging resumes
        });
        return;
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDrawing) return;
    if (_activePointers.length != 1) {
      // Multi-touch started — stop drawing, allow zoom
      setState(() => _isDrawing = false);
      return;
    }
    _addPointFromScreen(event.localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);

    if (_isDrawing) {
      setState(() => _isDrawing = false);
      return;
    }

    // Check for double-tap (2 quick taps) → set start point
    // Check for triple-tap (3 quick taps) → clear and restart
    if (_tapHistory.length >= 3) {
      final t1 = _tapHistory[_tapHistory.length - 3];
      final t2 = _tapHistory[_tapHistory.length - 2];
      final t3 = _tapHistory[_tapHistory.length - 1];
      final elapsed = t3.time.difference(t1.time).inMilliseconds;
      final dist1 = (t2.pos - t1.pos).distance;
      final dist2 = (t3.pos - t2.pos).distance;

      if (elapsed < 600 && dist1 < 50 && dist2 < 50) {
        // ====== TRIPLE TAP ======
        _tapHistory.clear();
        _onTripleTap(event.localPosition);
        return;
      }
    }

    if (_tapHistory.length >= 2) {
      final t1 = _tapHistory[_tapHistory.length - 2];
      final t2 = _tapHistory[_tapHistory.length - 1];
      final elapsed = t2.time.difference(t1.time).inMilliseconds;
      final dist = (t2.pos - t1.pos).distance;

      if (elapsed < 400 && dist < 50) {
        if (_pathPoints.isEmpty) {
          // ====== DOUBLE TAP (no path) → set start point ======
          _onDoubleTapStart(event.localPosition);
        } else {
          // ====== DOUBLE TAP (existing path) → finish / stop ======
          if (_isLiveTracking) {
            _toggleLiveTracking(); // Stops tracking
          }
          setState(() {
            _isDrawing = false;
            _showStats = true;
          });
        }
        return;
      }
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_isDrawing) setState(() => _isDrawing = false);
  }

  void _onDoubleTapStart(Offset screenPos) {
    try {
      final point = _mapController.camera
          .pointToLatLng(math.Point(screenPos.dx, screenPos.dy));
      setState(() {
        _pathPoints.add(point);
        _updateStats();
      });
    } catch (_) {}
  }

  void _onTripleTap(Offset screenPos) {
    try {
      final point = _mapController.camera
          .pointToLatLng(math.Point(screenPos.dx, screenPos.dy));
      setState(() {
        _pathPoints.clear();
        _pathPoints.add(point);
        _totalDistance = 0;
        _totalSteps = 0;
        _totalCalories = 0;
        _totalDuration = 0;
        _showStats = false;
        _isDrawing = false;
      });
    } catch (_) {}
  }

  void _addPointFromScreen(Offset pos) {
    try {
      final point =
          _mapController.camera.pointToLatLng(math.Point(pos.dx, pos.dy));
      if (_pathPoints.isNotEmpty) {
        final last = _pathPoints.last;
        final dx = (point.latitude - last.latitude).abs();
        final dy = (point.longitude - last.longitude).abs();
        if (dx < 0.00003 && dy < 0.00003) return;
      }
      setState(() {
        _pathPoints.add(point);
        _updateStats();
      });
    } catch (_) {}
  }

  void _updateStats() {
    _totalDistance = PathCalculator.calculatePathDistance(_pathPoints);
    _totalSteps = PathCalculator.calculateSteps(_totalDistance);
    _totalCalories = PathCalculator.calculateCalories(_totalDistance / 1000);
    _totalDuration = PathCalculator.estimateWalkingMinutes(_totalDistance);
  }

  void _undoLastPoint() {
    if (_pathPoints.isNotEmpty && !_isViewingExisting) {
      setState(() {
        final n = _pathPoints.length < 10 ? _pathPoints.length : 10;
        _pathPoints.removeRange(_pathPoints.length - n, _pathPoints.length);
        _updateStats();
      });
    }
  }

  void _clearPath() {
    if (!_isViewingExisting) {
      setState(() {
        _pathPoints.clear();
        _totalDistance = 0;
        _totalSteps = 0;
        _totalCalories = 0;
        _totalDuration = 0;
      });
    }
  }

  Future<void> _savePath() async {
    if (_pathPoints.length < 2) {
      _showMsg('Draw a path first');
      return;
    }
    final nc = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Save Route',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: nc,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Morning Walk',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.textMuted.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: AppColors.bgDark,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                ctx,
                nc.text.isEmpty
                    ? 'Route ${DateTime.now().day}/${DateTime.now().month}'
                    : nc.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (name != null && mounted) {
      await StorageService.saveRoute(
        name: name,
        points: _pathPoints,
        distanceMeters: _totalDistance,
        steps: _totalSteps,
        calories: _totalCalories,
        durationMinutes: _totalDuration,
      );
      _showMsg('Route "$name" saved! ✓');
    }
  }

  void _showMapProviderSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.55;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)))),
                const Text('Map Style',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Flexible(
                    child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mapProviders.length,
                  itemBuilder: (ctx, i) {
                    final sel = i == _selectedProviderIndex;
                    final p = _mapProviders[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedProviderIndex = i);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: sel ? 2 : 1)),
                          child: Row(children: [
                            Text(p.icon,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Text(p.name,
                                style: TextStyle(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                            const Spacer(),
                            if (sel)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20),
                          ]),
                        ),
                      ),
                    );
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    final topPad = MediaQuery.of(context).padding.top;
    final height = MediaQuery.of(context).size.height;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(
          left: 16, right: 16, bottom: height - topPad - 120),
      duration: const Duration(seconds: 2),
    ));
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    const double navH = 90;
    final provider = _mapProviders[_selectedProviderIndex];
    final safePad = MediaQuery.of(context).padding;

    // Map flags: no doubleTapZoom (we use it ourselves)
    // When drawing: only pinch zoom (no pan)
    final int normalFlags = InteractiveFlag.drag |
        InteractiveFlag.flingAnimation |
        InteractiveFlag.pinchMove |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.scrollWheelZoom |
        InteractiveFlag.rotate;
    const int drawingFlags = InteractiveFlag.pinchZoom;

    return Scaffold(
      body: Stack(
        children: [
          // ============ MAP ============
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 14.0,
                minZoom: 3.0,
                maxZoom: 20.0,
                interactionOptions: InteractionOptions(
                    flags: _isDrawing ? drawingFlags : normalFlags),
              ),
              children: [
                TileLayer(
                  urlTemplate: provider.url,
                  subdomains: provider.subdomains,
                  userAgentPackageName: 'com.via.app',
                  maxZoom: 20,
                  minZoom: 3,
                ),

                // Path
                if (_pathPoints.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(
                        points: _pathPoints,
                        strokeWidth: 14.0,
                        color: Colors.black.withValues(alpha: 0.15)),
                    Polyline(
                        points: _pathPoints,
                        strokeWidth: 7.0,
                        gradientColors: [
                          Colors.blue.shade400,
                          Colors.cyanAccent,
                          Colors.greenAccent,
                        ]),
                    Polyline(
                        points: _pathPoints,
                        strokeWidth: 2.0,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ]),

                MarkerLayer(markers: [
                  // User location
                  if (_userLocation != null)
                    Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: _isLiveTracking
                            ? Pulse(
                                infinite: true,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF2979FF),
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                            color: const Color(0xFF2979FF).withValues(alpha: 0.8),
                                            blurRadius: 20,
                                            spreadRadius: 6)
                                      ]),
                                  child: const Icon(Icons.my_location, color: Colors.white, size: 14),
                                ),
                              )
                            : Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2979FF),
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFF2979FF).withValues(alpha: 0.5),
                                          blurRadius: 12,
                                          spreadRadius: 3)
                                    ]),
                                child: const Icon(Icons.circle, color: Colors.white, size: 8),
                              )),

                  // Search marker
                  if (_searchMarker != null)
                    Marker(
                        point: _searchMarker!,
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.place_rounded,
                            color: Color(0xFFFF5722), size: 36)),

                  // Start (green)
                  if (_pathPoints.isNotEmpty)
                    Marker(
                        point: _pathPoints.first,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00C853),
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF00C853)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2)
                              ]),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 16),
                        )),

                  // End (red)
                  if (_pathPoints.length > 1)
                    Marker(
                        point: _pathPoints.last,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF1744),
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFFF1744)
                                        .withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2)
                              ]),
                          child: const Icon(Icons.flag_rounded,
                              color: Colors.white, size: 16),
                        )),

                  // Drag-from ring (shows where to drag from)
                  if (_pathPoints.isNotEmpty && !_isDrawing)
                    Marker(
                        point: _pathPoints.last,
                        width: 56,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  width: 2),
                              color:
                                  AppColors.primary.withValues(alpha: 0.06)),
                        )),
                ]),
              ],
            ),
          ),

          // ============ TOUCH LISTENER ============
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
            ),
          ),

          // ============ DRAWING BORDER ============
          if (_isDrawing)
            Positioned.fill(
                child: IgnorePointer(
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.6),
                                width: 3))))),

          // ============ WEATHER BEAD ============
          if (_weatherTemp != null && !_isViewingExisting)
            Positioned(
              top: safePad.top + 60,
              left: 12,
              child: ZoomIn(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                      child: Text(_weatherTemp!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ),

          // ============ STATS (BOTTOM) ============
          if (_showStats && _pathPoints.isNotEmpty && !_isDrawing)
            Positioned(
                bottom: navH + 80,
                left: 16,
                right: 16,
                child: FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: StatsPanel(
                        distance: _totalDistance,
                        steps: _totalSteps,
                        calories: _totalCalories,
                        duration: _totalDuration,
                        pointCount: _pathPoints.length,
                        currentSpeed: _currentSpeed))),

          // ============ TOP BAR ============
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.only(
                    top: safePad.top + 4, left: 12, right: 12, bottom: 8),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent
                    ])),
                child: Row(
                  children: [
                    if (_isViewingExisting) ...[
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Colors.black.withValues(alpha: 0.45)),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 17)),
                      const SizedBox(width: 8),
                      if (widget.routeName != null)
                        Expanded(
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Text(widget.routeName!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis))),
                    ],
                    if (!_isViewingExisting) const Spacer(),
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: _isDrawing
                              ? AppColors.primary
                              : Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14)),
                      child: Text(
                          _isDrawing
                              ? '✏️ ${PathCalculator.formatDistance(_totalDistance)}'
                              : _pathPoints.isEmpty
                                  ? 'Double-tap to start'
                                  : 'Double-tap to finish path',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (!_isViewingExisting) const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // ============ TOP-RIGHT BUTTONS ============
          Positioned(
            top: safePad.top + 8,
            right: 12,
            child: Column(children: [
              if (!_isViewingExisting) ...[
                // Search
                GestureDetector(
                  onTap: _showSearchDialog,
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(color: Colors.white24)),
                      child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 17)),
                ),
                const SizedBox(height: 8),
                // Layers
                GestureDetector(
                  onTap: _showMapProviderSheet,
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(color: Colors.white24)),
                      child: const Icon(Icons.layers_rounded,
                          color: Colors.white, size: 17)),
                ),
                const SizedBox(height: 12),
                // Live tracking
                GestureDetector(
                  onTap: _toggleLiveTracking,
                  child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isLiveTracking ? Colors.redAccent : AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                                color: (_isLiveTracking ? Colors.redAccent : AppColors.primary)
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2)
                          ]),
                      child: Icon(
                          _isLiveTracking ? Icons.stop_rounded : Icons.directions_run_rounded,
                          color: Colors.white,
                          size: 22)),
                ),
              ],
              if (_isViewingExisting)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(color: Colors.white24)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 17)),
                ),
            ]),
          ),

          // ============ HINT ============
          if (_showHint && _pathPoints.isEmpty && !_isDrawing)
            Positioned(
              bottom: navH + 80,
              left: 32,
              right: 32,
              child: FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24)),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('👆 Double-tap to set start point',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(height: 6),
                                Text(
                                    '☝️ Drag from end point to draw path\n👆👆 Double-tap to finish\n👆👆👆 Triple-tap to restart',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -8,
                            child: GestureDetector(
                              onTap: _dismissHint,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                              ),
                            ),
                          )
                        ],
                      ))),
            ),

          // ============ BOTTOM CONTROLS ============
          if (!_isDrawing)
            Positioned(
              bottom: navH + 12,
              left: 12,
              child: ZoomIn(
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _centerOnLocation,
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _userLocation != null
                              ? AppColors.primaryGradient
                              : LinearGradient(colors: [
                                  Colors.white,
                                  Colors.grey.shade100,
                                ]),
                          boxShadow: [
                            BoxShadow(
                                color: _userLocation != null
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4))
                          ]),
                      child: _isLocating
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.blue))
                          : Icon(
                              _userLocation != null
                                  ? Icons.my_location_rounded
                                  : Icons.location_searching_rounded,
                              color: _userLocation != null
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              size: 22)),
                ),
              ),
            ),

          if (!_isDrawing && _pathPoints.isNotEmpty)
            Positioned(
              bottom: navH + 12,
              right: 12,
              child: ZoomIn(
                duration: const Duration(milliseconds: 300),
                child: _buildPathActionBar(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPathActionBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isViewingExisting) ...[
                _actionBtn(Icons.undo_rounded, 'Undo', Colors.white70, _undoLastPoint),
                _divider(),
                _actionBtn(Icons.delete_sweep_rounded, 'Clear', Colors.redAccent.shade200, _clearPath),
                _divider(),
              ],
              _actionBtn(_showStats ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                         'Stats', Colors.white70, () => setState(() => _showStats = !_showStats)),
              if (!_isViewingExisting && _pathPoints.length >= 2) ...[
                _divider(),
                _actionBtn(Icons.save_rounded, 'Save', Colors.greenAccent.shade400, _savePath, isPrimary: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
      height: 20, width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: Colors.white24);

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

// Simple tap record for multi-tap detection
class _TapRecord {
  final DateTime time;
  final Offset pos;
  _TapRecord(this.time, this.pos);
}
