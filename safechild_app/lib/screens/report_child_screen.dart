import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart';
import '../services/localization_service.dart';
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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() => _position = position);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isAnalyzing = true;
      });

      // AI Analysis
      final faces = await _aiService.detectFaces(_image!);
      setState(() {
        _facesDetected = faces.length;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _submit() async {
    final tr = AppTranslations.of(context);
    if (!_formKey.currentState!.validate() || _position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.translate('gps_required_alert'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiServiceProvider);
      
      final formData = FormData.fromMap({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'alert_type': _selectedAlertType,
        'description': _descController.text.trim(),
        'last_clothes': _clothesController.text.trim(),
        'disappearance_lat': _position!.latitude,
        'disappearance_lng': _position!.longitude,
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

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        errMsg = e.response?.data?['message'] ?? e.message ?? e.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $errMsg'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
            const Icon(Icons.verified_user_outlined, color: Colors.blue, size: 60),
            const SizedBox(height: 10),
            Text(tr.translate('alert_submitted_title'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr.translate('alert_submitted_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.translate('authority_notice_desc'),
                      style: TextStyle(color: Colors.blue[900], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK, J\'AI COMPRIS'),
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
                Lottie.network('https://assets2.lottiefiles.com/packages/lf20_st968skv.json', height: 200),
                Text(tr.translate('processing_alert'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.blue[900], size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.translate('authority_notice_title'),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 13),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr.translate('authority_notice_desc'),
                                style: TextStyle(color: Colors.blue[800], fontSize: 12),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        _buildTypeOption(
                          type: 'child_missing',
                          label: tr.translate('filter_children'),
                          icon: Icons.child_care,
                          activeColor: Colors.blue[700]!,
                        ),
                        _buildTypeOption(
                          type: 'adult_missing',
                          label: tr.translate('filter_adults'),
                          icon: Icons.person,
                          activeColor: Colors.purple[700]!,
                        ),
                        _buildTypeOption(
                          type: 'wanted_person',
                          label: tr.translate('filter_wanted'),
                          icon: Icons.warning_amber_rounded,
                          activeColor: Colors.red[700]!,
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
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _facesDetected > 0 ? Colors.green : Colors.grey[300]!, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_image != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 45, color: Colors.blue[900]),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedAlertType == 'child_missing' 
                                    ? tr.translate('add_child_photo') 
                                    : tr.translate('add_person_photo'),
                                  style: TextStyle(color: Colors.blue[900]),
                                ),
                              ],
                            ),
                          if (_isAnalyzing)
                            Container(
                              color: Colors.black45,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.network('https://assets5.lottiefiles.com/packages/lf20_t9gkkhz4.json', height: 80),
                                  Text(tr.translate('ia_analyzing'), style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          if (_facesDetected > 0 && !_isAnalyzing)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.face, color: Colors.white, size: 16),
                                    const SizedBox(width: 5),
                                    Text(tr.translate('face_detected'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  _buildInputLabel(tr.translate('basic_info')),
                  _buildStyledField(
                    controller: _nameController, 
                    hint: _selectedAlertType == 'child_missing' ? tr.translate('child_name_hint') : tr.translate('person_name_hint'), 
                    icon: Icons.person_outline
                  ),
                  _buildStyledField(
                    controller: _ageController, 
                    hint: tr.translate('age_hint'), 
                    icon: Icons.cake_outlined, 
                    keyboardType: TextInputType.number
                  ),
                  
                  const SizedBox(height: 15),
                  _buildInputLabel(tr.translate('physical_desc')),
                  _buildStyledField(controller: _clothesController, hint: tr.translate('clothes_hint'), icon: Icons.checkroom_outlined),
                  _buildStyledField(controller: _descController, hint: tr.translate('desc_hint'), icon: Icons.description_outlined, maxLines: 3),
                  
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          tr.translate('submit_for_review_btn'), 
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)
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

  Widget _buildTypeOption({required String type, required String label, required IconData icon, required Color activeColor}) {
    final isSelected = _selectedAlertType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAlertType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: isSelected ? Border.all(color: activeColor, width: 2) : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey[600], size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey[700],
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
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 16)),
    );
  }

  Widget _buildStyledField({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType, int maxLines = 1}) {
    final tr = AppTranslations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue[900]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        validator: (val) => val == null || val.isEmpty ? tr.translate('required') : null,
      ),
    );
  }
}
 