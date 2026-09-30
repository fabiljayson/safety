import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../models/missing_child.dart';
import '../services/localization_service.dart';
import 'report_child_screen.dart';
import 'home_screen.dart'; // Pour missingChildrenProvider et dangerZonesProvider
import 'child_detail_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(0, 0);
  bool _showHeatmap = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      // Geolocation unavailable on this platform (e.g. Linux desktop).
      debugPrint('Location unavailable: $e');
      return;
    }
    if (!serviceEnabled) return;

    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newLatLng;
      });
      _mapController.move(newLatLng, 15.0);
    } catch (e) {
      debugPrint('Could not determine position: $e');
    }
  }

  Color _getMarkerColor(MissingChild child) {
    if (child.alertType == 'wanted_person') return Colors.red[700]!;
    if (child.alertType == 'adult_missing') return Colors.purple[700]!;
    return child.isVerified ? Colors.blue[700]! : Colors.amber[800]!;
  }

  @override
  Widget build(BuildContext context) {
    final missingChildren = ref.watch(missingChildrenProvider);
    final dangerZones = ref.watch(dangerZonesProvider);
    final tr = AppTranslations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentCenter, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safechild_app',
              ),
              if (_showHeatmap)
                CircleLayer(
                  circles: dangerZones.when(
                    data: (zones) => zones
                        .map(
                          (zone) => CircleMarker(
                            point: LatLng(
                              zone.point.latitude,
                              zone.point.longitude,
                            ),
                            radius: 50 * zone.weight,
                            useRadiusInMeter: true,
                            color: Colors.red.withValues(alpha: 0.3),
                            borderColor: Colors.red.withValues(alpha: 0.6),
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList()
                        .cast<CircleMarker>(),
                    loading: () => <CircleMarker>[],
                    error: (_, _) => <CircleMarker>[],
                  ),
                ),
              MarkerLayer(
                markers: [
                  // Current Location Marker
                  if (_currentCenter.latitude != 0)
                    Marker(
                      point: _currentCenter,
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  // Missing Persons & Wanted Markers
                  if (!_showHeatmap)
                    ...missingChildren.when(
                      data: (children) {
                        final filtered = _selectedFilter == 'all'
                            ? children
                            : children
                                  .where((c) => c.alertType == _selectedFilter)
                                  .toList();

                        return filtered
                            .map(
                              (child) => Marker(
                                point: LatLng(
                                  child.disappearanceLat,
                                  child.disappearanceLng,
                                ),
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () => _showChildDetails(child, tr),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 44,
                                        color: _getMarkerColor(child),
                                      ),
                                      Positioned(
                                        top: 8,
                                        child: Icon(
                                          child.alertType == 'wanted_person'
                                              ? Icons.warning_rounded
                                              : child.alertType ==
                                                    'adult_missing'
                                              ? Icons.person
                                              : Icons.child_care,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList();
                      },
                      loading: () => [],
                      error: (_, _) => [],
                    ),
                ],
              ),
            ],
          ),

          // Category Filter Chips on Top
          Positioned(
            top: 20,
            left: 15,
            right: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'all',
                    tr.translate('filter_all'),
                    Colors.blue[900]!,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    'child_missing',
                    '👶 ${tr.translate('filter_children')}',
                    Colors.blue[700]!,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    'adult_missing',
                    '🧓 ${tr.translate('filter_adults')}',
                    Colors.purple[700]!,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    'wanted_person',
                    '🚨 ${tr.translate('filter_wanted')}',
                    Colors.red[700]!,
                  ),
                ],
              ),
            ),
          ),

          // Map Controls with Labels
          Positioned(
            top: 20,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMapButton(
                  label: _showHeatmap
                      ? tr.translate('map_mode')
                      : tr.translate('risk_zones'),
                  icon: _showHeatmap ? Icons.map : Icons.local_fire_department,
                  color: _showHeatmap ? Colors.blue : Colors.red,
                  onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
                ),
                const SizedBox(height: 12),
                _buildMapButton(
                  label: tr.translate('my_position'),
                  icon: Icons.my_location,
                  color: Colors.blue[900]!,
                  onPressed: _determinePosition,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ReportChildScreen()));
        },
        label: Text(
          tr.translate('launch_alert_btn'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_alert),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, Color color) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: Colors.white,
          child: Icon(icon, color: color),
        ),
      ],
    );
  }

  void _showChildDetails(MissingChild child, AppTranslations tr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (child.isVerified)
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(tr.missingSince(child.disappearedAt)),
            const SizedBox(height: 4),
            Text(tr.ageLabel(child.age)),
            const SizedBox(height: 10),
            if (child.description != null)
              Text(child.description!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(
                        tr
                            .translate('share_alert_message')
                            .replaceAll('{name}', child.name)
                            .replaceAll('{age}', child.age.toString()),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: Text(tr.translate('share')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChildDetailScreen(child: child),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: Text(
                      tr.translate('report_and_details'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
