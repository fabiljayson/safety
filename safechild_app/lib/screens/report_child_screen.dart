import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ReportChildScreen extends ConsumerStatefulWidget {
  const ReportChildScreen({super.key});

  @override
  ConsumerState<ReportChildScreen> createState() => _ReportChildScreenState();
}

class _ReportChildScreenState extends ConsumerState<ReportChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descController = TextEditingController();
  final _clothesController = TextEditingController();
  final AIService _aiService = AIService();

  String _selectedAlertType = 'child_missing';
  File? _image;
  Position? _position;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  int _facesDetected = 0;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _aiService.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _descController.dispose();
    _clothesController.dispose();
    super.dispose();
  }

  /// Resolves the position the report is filed at.
  ///
  /// The location is mandatory for an alert, so a failure has to be visible to
  /// the user rather than silently dropping the coordinates. Permission and
  /// platform errors are caught because `getCurrentPosition` throws when
  /// location services are off, permission is denied, or the platform has no
  /// geolocation provider at all (Linux desktop).
  Future<void> _determinePosition() async {
    // Resolved before the first await: reading it after an async gap would
    // touch a BuildContext that may already be unmounted.
    final tr = AppTranslations.of(context);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLocationError(tr: tr, serviceOff: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationError(tr: tr);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _position = position;
        _locationError = null;
      });
    } catch (e) {
      debugPrint('Could not determine position: $e');
      if (!mounted) return;
      _setLocationError(tr: tr);
    }
  }

  void _setLocationError({
    required AppTranslations tr,
    bool serviceOff = false,
  }) {
    if (!mounted) return;

    setState(() {
      _locationError = serviceOff
          ? tr.translate('location_service_off')
          : tr.translate('location_permission_denied');
    });
  }

  Future<void> _pickImage() async {
    final tr = AppTranslations.of(context);

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (pickedFile == null || !mounted) return;

      setState(() {
        _image = File(pickedFile.path);
        _isAnalyzing = true;
        _facesDetected = 0;
      });

      final faces = await _aiService.detectFaces(_image!);
      if (!mounted) return;

      setState(() {
        _facesDetected = faces.length;
        _isAnalyzing = false;
      });
    } catch (e) {
      debugPrint('Could not analyse the selected photo: $e');
      if (!mounted) return;

      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${tr.translate('error')}: $e')));
    }
  }

  Future<void> _submit() async {
    final tr = AppTranslations.of(context);

    if (!_formKey.currentState!.validate() || _position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationError ?? tr.translate('gps_required_alert')),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      final position = _position!;

      final formData = FormData.fromMap({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'alert_type': _selectedAlertType,
        'description': _descController.text.trim(),
        'last_clothes': _clothesController.text.trim(),
        'disappearance_lat': position.latitude,
        'disappearance_lng': position.longitude,
        'disappeared_at': DateTime.now().toIso8601String(),
        if (_image != null)
          'photo': await MultipartFile.fromFile(
            _image!.path,
            filename: _image!.path.split('/').last,
          ),
      });

      await api.post('/missing-children', data: formData);

      // Invalidate both providers to refresh list and maps
      ref.invalidate(missingChildrenProvider);
      ref.invalidate(dangerZonesProvider);

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      final errMsg = describeApiError(
        e,
        connectionMessage: tr.translate('connection_error_api'),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        // No custom background: the theme's floating snackbar is already
        // high-contrast in both light and dark mode, which a hand-picked
        // accent red was not.
        SnackBar(content: Text('${tr.translate('error')}: $errMsg')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    final tr = AppTranslations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              tr.translate('alert_submitted_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr.translate('alert_submitted_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.translate('authority_notice_desc'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(tr.translate('understood')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppTranslations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr.translate('report_missing'))),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    tr.translate('processing_alert'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Authority Notice Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.translate('authority_notice_title'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  tr.translate('authority_notice_desc'),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alert Type Selector
                    _buildInputLabel(tr.translate('alert_type_label')),
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildTypeOption(
                            type: 'child_missing',
                            label: tr.translate('filter_children'),
                            icon: Icons.child_care,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          _buildTypeOption(
                            type: 'adult_missing',
                            label: tr.translate('filter_adults'),
                            icon: Icons.person,
                            activeColor: context.colors.adultMissing,
                          ),
                          _buildTypeOption(
                            type: 'wanted_person',
                            label: tr.translate('filter_wanted'),
                            icon: Icons.warning_amber_rounded,
                            activeColor: context.colors.urgent,
                          ),
                        ],
                      ),
                    ),

                    // Image Picker Area with AI status
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _facesDetected > 0
                                ? context.colors.verified
                                : context.colors.borderSubtle,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_image != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 45,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedAlertType == 'child_missing'
                                        ? tr.translate('add_child_photo')
                                        : tr.translate('add_person_photo'),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            if (_isAnalyzing)
                              Container(
                                color: Colors.black45,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      tr.translate('ia_analyzing'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_facesDetected > 0 && !_isAnalyzing)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.colors.verified,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.face,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        tr.translate('face_detected'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    if (_locationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _determinePosition,
                              child: Text(tr.translate('retry')),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    _buildInputLabel(tr.translate('basic_info')),

                    _buildStyledField(
                      controller: _nameController,
                      hint: _selectedAlertType == 'child_missing'
                          ? tr.translate('child_name_hint')
                          : tr.translate('person_name_hint'),
                      icon: Icons.person_outline,
                    ),
                    _buildStyledField(
                      controller: _ageController,
                      hint: tr.translate('age_hint'),
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 15),
                    _buildInputLabel(tr.translate('physical_desc')),
                    _buildStyledField(
                      controller: _clothesController,
                      hint: tr.translate('clothes_hint'),
                      icon: Icons.checkroom_outlined,
                    ),
                    _buildStyledField(
                      controller: _descController,
                      hint: tr.translate('desc_hint'),
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr.translate('submit_for_review_btn'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedAlertType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAlertType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: isSelected
                ? Border.all(color: activeColor, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? activeColor
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? activeColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final tr = AppTranslations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        validator: (val) =>
            val == null || val.isEmpty ? tr.translate('required') : null,
      ),
    );
  }
}
