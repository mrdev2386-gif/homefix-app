import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/technician_service_service.dart';
import '../../core/models/technician_service.dart';
import '../../core/utils/service_image_utils.dart';

/// Multi-step service creation form
/// Step 1: Service Selection (Category & Subcategory)
/// Step 2: Service Details (Title, Description, Tags, Duration, Price)
/// Step 3: Media Upload (Image)
/// Step 4: Review & Publish
class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = 4;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Form data
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _priceController = TextEditingController();
  
  int _durationValue = 30;
  String _durationUnit = 'minutes'; // 'minutes' or 'hours'
  
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  // Categories cache
  List<dynamic> _categories = [];
  Map<String, List<dynamic>> _subcategories = {};
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      
      setState(() {
        _categories = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unknown',
          ...doc.data(),
        }).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      
      setState(() {
        _subcategories[categoryId] = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unknown',
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    setState(() => _errorMessage = null);
    
    switch (_currentStep) {
      case 0: // Category & Subcategory
        if (_selectedCategoryId == null) {
          setState(() => _errorMessage = 'Please select a category');
          return false;
        }
        if (_selectedSubcategoryId == null) {
          setState(() => _errorMessage = 'Please select a subcategory');
          return false;
        }
        return true;
        
      case 1: // Service Details
        if (_titleController.text.trim().length < 3) {
          setState(() => _errorMessage = 'Title must be at least 3 characters');
          return false;
        }
        if (_descriptionController.text.trim().length < 20) {
          setState(() => _errorMessage = 'Description must be at least 20 characters');
          return false;
        }
        final price = double.tryParse(_priceController.text);
        if (price == null || price <= 0) {
          setState(() => _errorMessage = 'Price must be greater than 0');
          return false;
        }
        if (_durationValue <= 0) {
          setState(() => _errorMessage = 'Duration must be greater than 0');
          return false;
        }
        return true;
        
      case 2: // Image
        if (_uploadedImageUrl == null && _selectedImage == null) {
          setState(() => _errorMessage = 'Please upload a service image');
          return false;
        }
        return true;
        
      case 3: // Review
        return true;
        
      default:
        return true;
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final image = await ServiceImageUtils.pickImage();
      if (image == null) return;

      // Validate
      final validationError = await ServiceImageUtils.validateImage(image);
      if (validationError != null) {
        setState(() => _errorMessage = validationError);
        return;
      }

      setState(() {
        _selectedImage = image;
        _isUploading = true;
        _errorMessage = null;
      });

      // Upload
      final url = await ServiceImageUtils.uploadServiceImage(image);
      
      setState(() {
        _uploadedImageUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload image: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _publishService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .take(10)
          .toList();

      // Calculate duration in minutes
      final durationMinutes = _durationUnit == 'hours' 
          ? _durationValue * 60 
          : _durationValue;

      // Create input
      final input = CreateTechnicianServiceInput(
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: tags,
        price: double.parse(_priceController.text),
        durationMinutes: durationMinutes,
        imageUrl: _uploadedImageUrl!,
      );

      // Call Cloud Function
      final service = await context.read<TechnicianCatalogService>().createService(input);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(service);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(),
        ),
      ),
      body: Column(
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1CategorySelection(),
                _buildStep2ServiceDetails(),
                _buildStep3MediaUpload(),
                _buildStep4Review(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted 
                        ? Colors.green 
                        : (isActive ? Theme.of(context).primaryColor : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading || _isUploading
                    ? null
                    : (_currentStep == _totalSteps - 1 ? _publishService : _nextStep),
                child: _isLoading || _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_currentStep == _totalSteps - 1 ? 'Publish Service' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Category Selection
  Widget _buildStep1CategorySelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Select Service Category',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the category and subcategory that best describes your service.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Category dropdown
          const Text('Category *', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a category',
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat['id'] as String,
                  child: Text(cat['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _selectedCategoryName = _categories
                      .firstWhere((c) => c['id'] == value)['name'] as String;
                  _selectedSubcategoryId = null;
                  _selectedSubcategoryName = null;
                });
                if (value != null) {
                  _loadSubcategories(value);
                }
              },
            ),

          const SizedBox(height: 24),

          // Subcategory dropdown
          const Text('Subcategory *', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSubcategoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a subcategory',
            ),
            items: (_subcategories[_selectedCategoryId] ?? []).map((sub) {
              return DropdownMenuItem(
                value: sub['id'] as String,
                child: Text(sub['name'] as String),
              );
            }).toList(),
            onChanged: _selectedCategoryId == null
                ? null
                : (value) {
                    setState(() {
                      _selectedSubcategoryId = value;
                      _selectedSubcategoryName = (_subcategories[_selectedCategoryId] ?? [])
                          .firstWhere((s) => s['id'] == value)['name'] as String;
                    });
                  },
          ),
        ],
      ),
    );
  }

  // Step 2: Service Details
  Widget _buildStep2ServiceDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Service Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide detailed information about your service.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Title
          const Text('Service Title *', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g., AC Repair & Service',
            ),
            maxLength: 100,
          ),

          const SizedBox(height: 16),

          // Description
          const Text('Description *', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Describe your service in detail (min 20 characters)...',
            ),
            maxLines: 4,
            maxLength: 1000,
          ),

          const SizedBox(height: 16),

          // Tags
          const Text('Tags (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text(
            'Comma-separated keywords to help customers find your service',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g., ac, repair, cooling, maintenance',
            ),
          ),

          const SizedBox(height: 24),

          // Duration & Price Row
          Row(
            children: [
              // Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duration *', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _durationValue.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              _durationValue = int.tryParse(v) ?? _durationValue;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _durationUnit,
                          items: const [
                            DropdownMenuItem(value: 'minutes', child: Text('min')),
                            DropdownMenuItem(value: 'hours', child: Text('hrs')),
                          ],
                          onChanged: (v) => setState(() => _durationUnit = v!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Price (₹) *', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Media Upload
  Widget _buildStep3MediaUpload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3: Service Image',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a high-quality image that represents your service.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Image preview
          Center(
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadImage,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _uploadedImageUrl != null 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : _uploadedImageUrl != null || _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _uploadedImageUrl ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                            ),
                          )
                        : _buildImagePlaceholder(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Image requirements
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Image Requirements',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• Format: JPG, PNG, or WebP', style: TextStyle(fontSize: 13)),
                const Text('• Size: Max 10MB', style: TextStyle(fontSize: 13)),
                const Text('• Aspect Ratio: 1:1 (square) - will be cropped automatically', style: TextStyle(fontSize: 13)),
                const Text('• Recommended: High quality, well-lit image', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Tap to upload image',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Step 4: Review
  Widget _buildStep4Review() {
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final durationDisplay = _durationUnit == 'hours' 
        ? '$_durationValue hour${_durationValue > 1 ? 's' : ''}'
        : '$_durationValue minutes';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 4: Review Your Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your service details before publishing.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Preview Card
          Card(
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (_uploadedImageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        _uploadedImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedCategoryName ?? 'Category',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        _titleController.text.isNotEmpty 
                            ? _titleController.text 
                            : 'Service Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        _selectedSubcategoryName ?? 'Subcategory',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        _descriptionController.text.isNotEmpty 
                            ? _descriptionController.text 
                            : 'Description',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      // Tags
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Price & Duration Row
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(durationDisplay, style: const TextStyle(color: Colors.grey)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹${_priceController.text}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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

          const SizedBox(height: 24),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Once published, your service will be visible to customers. You can edit or delete it anytime.',
                    style: TextStyle(fontSize: 13),
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
