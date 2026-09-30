import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/missing_child.dart';
import 'home_screen.dart'; // to invalidate missingChildrenProvider if child status changes

final childSightingsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  childId,
) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get(
    '/reports',
    queryParameters: {'missing_child_id': childId},
  );
  return response.data as List<dynamic>;
});

class ChildDetailScreen extends ConsumerStatefulWidget {
  final MissingChild child;
  const ChildDetailScreen({super.key, required this.child});

  @override
  ConsumerState<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends ConsumerState<ChildDetailScreen> {
  final _sightingFormKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  File? _sightingImage;
  bool _isSubmittingSighting = false;
  Position? _currentPosition;
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Resolves the position a sighting would be filed at.
  ///
  /// Every setState is guarded because the user can leave the screen while a
  /// permission prompt is open or while the GPS fix is pending.
  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _stopFetchingLocation();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _stopFetchingLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _fetchingLocation = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      _stopFetchingLocation();
    }
  }

  void _stopFetchingLocation() {
    if (!mounted) return;
    setState(() => _fetchingLocation = false);
  }

  Future<void> _pickSightingImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (pickedFile == null || !mounted) return;

      setState(() => _sightingImage = File(pickedFile.path));
    } catch (e) {
      debugPrint('Could not attach a sighting photo: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppTranslations.of(context).translate('error')}: $e',
          ),
        ),
      );
    }
  }

  Future<void> _submitSighting() async {
    final tr = AppTranslations.of(context);
    if (!_sightingFormKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.translate('gps_sighting_required'))),
      );
      return;
    }

    setState(() => _isSubmittingSighting = true);

    try {
      final api = ref.read(apiServiceProvider);

      final formData = FormData.fromMap({
        'missing_child_id': widget.child.id,
        'lat': _currentPosition!.latitude,
        'lng': _currentPosition!.longitude,
        'sighted_at': DateTime.now().toIso8601String(),
        'description': _descriptionController.text.trim(),
        if (_sightingImage != null)
          'photo': await MultipartFile.fromFile(
            _sightingImage!.path,
            filename: _sightingImage!.path.split('/').last,
          ),
      });

      await api.post('/reports', data: formData);

      // Refresh sightings
      ref.invalidate(childSightingsProvider(widget.child.id!));
      // Refresh heatmap
      ref.invalidate(dangerZonesProvider);

      if (!mounted) return;

      _descriptionController.clear();
      setState(() => _sightingImage = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr.translate('sighting_success_msg')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tr.translate('error')}: ${describeApiError(e)}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingSighting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppTranslations.of(context);
    final sightingsAsync = ref.watch(childSightingsProvider(widget.child.id!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.child.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Child Card with Photo
            Stack(
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: widget.child.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.child.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.child.photoUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                // Status and Verification Badges
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.child.status == 'missing'
                              ? Colors.red[700]
                              : Colors.green[700],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          widget.child.status == 'missing'
                              ? tr.translate('missing').toUpperCase()
                              : tr.translate('found').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Alert Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.child.alertType == 'wanted_person'
                              ? Colors.red[900]
                              : widget.child.alertType == 'adult_missing'
                              ? Colors.purple[800]
                              : Colors.blue[900],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          widget.child.alertType == 'wanted_person'
                              ? '🚨 ${tr.translate('filter_wanted').toUpperCase()}'
                              : widget.child.alertType == 'adult_missing'
                              ? '🧓 ${tr.translate('filter_adults').toUpperCase()}'
                              : '👶 ${tr.translate('filter_children').toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.child.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tr.translate('published_alert').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Child info details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.child.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${widget.child.age} ${tr.translate('age_hint') == 'Âge' ? 'ans' : 'years old'}",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${tr.translate('disappeared_on')} ${widget.child.disappearedAt.day}/${widget.child.disappearedAt.month}/${widget.child.disappearedAt.year}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 30),

                  // Clothing Card
                  if (widget.child.lastClothes != null &&
                      widget.child.lastClothes!.isNotEmpty) ...[
                    _buildSectionHeader(
                      tr.translate('physical_desc'),
                      Icons.checkroom,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        widget.child.lastClothes!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description Card
                  if (widget.child.description != null &&
                      widget.child.description!.isNotEmpty) ...[
                    _buildSectionHeader(
                      tr.translate('particulars_desc_title'),
                      Icons.description_outlined,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.child.description!,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 25),
                  ],

                  const Divider(),
                  const SizedBox(height: 10),

                  // Sighting Report Section
                  _buildSectionHeader(
                    tr.translate('report_sighting_title'),
                    Icons.add_location_alt_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildSightingForm(),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Recent Sighting List
                  _buildSectionHeader(
                    tr.translate('sightings_reported_title'),
                    Icons.history,
                  ),
                  const SizedBox(height: 12),
                  sightingsAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              tr.translate('no_sightings_msg'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final sighting = list[index];
                          final dateStr =
                              DateTime.tryParse(sighting['sighted_at'] ?? '') ??
                              DateTime.now();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (sighting['photo_url'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        sighting['photo_url'],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sighting['description'] ??
                                              tr.translate(
                                                'Pas de description',
                                              ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${tr.translate('sighting_by')} ${sighting['user']?['name'] ?? 'Témoin'}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              "${dateStr.day}/${dateStr.month} ${tr.translate('sighting_at')} ${dateStr.hour}:${dateStr.minute.toString().padLeft(2, '0')}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text("${tr.translate('error')}: $err"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[900], size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  Widget _buildSightingForm() {
    final tr = AppTranslations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: _sightingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sighting Image Picker
            GestureDetector(
              onTap: _pickSightingImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _sightingImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _sightingImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.blue[900],
                            size: 30,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr.translate('add_sighting_photo_hint'),
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Location coordinates display / request
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _currentPosition != null
                              ? Icons.gps_fixed
                              : Icons.gps_off,
                          color: _currentPosition != null
                              ? Colors.green
                              : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentPosition != null
                                ? "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}"
                                : tr.translate('gps_not_acquired'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _fetchingLocation ? null : _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _fetchingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(tr.translate('activate_gps_btn')),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description field
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: tr.translate('sighting_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(12),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? tr.translate('required') : null,
            ),
            const SizedBox(height: 15),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmittingSighting ? null : _submitSighting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSubmittingSighting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      tr.translate('send_sighting_btn'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
