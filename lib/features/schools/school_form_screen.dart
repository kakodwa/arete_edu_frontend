import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../core/responsive.dart';

class SchoolFormScreen extends StatefulWidget {
  final Map<String, dynamic>? school;

  const SchoolFormScreen({super.key, this.school});

  @override
  State<SchoolFormScreen> createState() => _SchoolFormScreenState();
}

class _SchoolFormScreenState extends State<SchoolFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _curriculumController;
  late TextEditingController _overviewController;
  late TextEditingController _performanceController;
  late TextEditingController _tuitionMinController;
  late TextEditingController _tuitionMaxController;
  late TextEditingController _appFeeController;

  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.school;
    _nameController = TextEditingController(text: s?['name'] ?? '');
    _slugController = TextEditingController(text: s?['slug'] ?? '');
    _cityController = TextEditingController(text: s?['city'] ?? 'Lilongwe');
    _addressController = TextEditingController(text: s?['address'] ?? '');
    _latController = TextEditingController(text: s?['latitude']?.toString() ?? '');
    _lngController = TextEditingController(text: s?['longitude']?.toString() ?? '');
    _curriculumController = TextEditingController(text: s?['curriculum'] ?? 'MANEB');
    _overviewController = TextEditingController(text: s?['overview'] ?? '');
    _performanceController = TextEditingController(text: s?['exam_performance_summary'] ?? '');
    _tuitionMinController = TextEditingController(text: s?['annual_tuition_min']?.toString() ?? '250000');
    _tuitionMaxController = TextEditingController(text: s?['annual_tuition_max']?.toString() ?? '750000');
    _appFeeController = TextEditingController(text: s?['application_fee']?.toString() ?? '15000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _curriculumController.dispose();
    _overviewController.dispose();
    _performanceController.dispose();
    _tuitionMinController.dispose();
    _tuitionMaxController.dispose();
    _appFeeController.dispose();
    super.dispose();
  }

  void _generateSlugFromName(String name) {
    if (widget.school == null) {
      final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
      _slugController.text = slug;
    }
  }

  Future<void> _captureCurrentGPS() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
        );
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied. Enter coordinates manually.')),
        );
        setState(() => _isLocating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campus GPS coordinates captured!'), backgroundColor: AppColors.successGreen),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not acquire GPS fix. You can also enter Lat/Lng manually.')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _saveSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'name': _nameController.text.trim(),
      'slug': _slugController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      'latitude': _latController.text.trim().isNotEmpty ? double.tryParse(_latController.text.trim()) : null,
      'longitude': _lngController.text.trim().isNotEmpty ? double.tryParse(_lngController.text.trim()) : null,
      'curriculum': _curriculumController.text.trim(),
      'overview': _overviewController.text.trim(),
      'exam_performance_summary': _performanceController.text.trim(),
      'annual_tuition_min': double.tryParse(_tuitionMinController.text) ?? 0.0,
      'annual_tuition_max': double.tryParse(_tuitionMaxController.text) ?? 0.0,
      'application_fee': double.tryParse(_appFeeController.text) ?? 15000.0,
    };

    try {
      final isEditing = widget.school != null;
      final endpoint = isEditing ? 'schools/${widget.school!['id']}/' : 'schools/';
      final response = isEditing ? await ApiService.put(endpoint, payload) : await ApiService.post(endpoint, payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'School details updated!' : 'School listed successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final err = jsonDecode(response.body);
        setState(() => _errorMessage = err.toString());
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save school profile. Check network connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.school != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit School Profile' : 'Post / Register School'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 800,
            child: SoftCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'School Name (e.g. Maranatha Boys Academy)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _generateSlugFromName,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter school name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _slugController,
                      decoration: const InputDecoration(
                        labelText: 'School Slug / URL identifier',
                        border: OutlineInputBorder(),
                        helperText: 'Unique identifier (e.g., maranatha-boys)',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter unique slug' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City (e.g. Blantyre, Lilongwe)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _curriculumController,
                            decoration: const InputDecoration(
                              labelText: 'Curriculum (MANEB / Cambridge)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Campus Physical Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // GPS Coordinates Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.gps_fixed, color: AppColors.primaryTeal, size: 20),
                                  SizedBox(width: 8),
                                  Text('Campus GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: _isLocating
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.my_location, size: 16),
                                label: const Text('Use Current GPS', style: TextStyle(fontSize: 12)),
                                onPressed: _isLocating ? null : _captureCurrentGPS,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude (e.g. -13.9626)',
                                    border: OutlineInputBorder(),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _lngController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude (e.g. 33.7741)',
                                    border: OutlineInputBorder(),
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tuitionMinController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Tuition (MWK)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _tuitionMaxController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Tuition (MWK)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _appFeeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Application / Registration Fee (MWK)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _overviewController,
                      decoration: const InputDecoration(
                        labelText: 'School Overview & Campus Facilities',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Provide brief school description' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _performanceController,
                      decoration: const InputDecoration(
                        labelText: 'National / International Exam Track Record',
                        border: OutlineInputBorder(),
                        helperText: 'e.g. MSCE pass rate 98%, Cambridge A* highlights',
                      ),
                      maxLines: 3,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _saveSchool,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEditing ? 'Save Changes' : 'Submit & Post School', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
