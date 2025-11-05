import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final MapService _mapService = MapService();
  Building? _selectedBuilding; 
  
  String _postType = 'Lost Item';
  String _selectedCategory = 'IDs';
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'IDs', 'Gadgets', 'Wallet', 'Books', 'Clothing', 'Others'
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;
    if (!mounted) return;

    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    
    _timeController.text =
        "${combined.month}/${combined.day}/${combined.year} at ${pickedTime.format(context)}";
  }

  Future<void> _submitPost() async {
    if (_itemNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedBuilding == null ||
        _timeController.text.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      String imageUrl = '';

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userName': userName.isEmpty ? 'Anonymous' : userName,
        'itemStatus': _postType == 'Lost Item' ? 'Lost' : 'Found',
        'itemName': _itemNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'itemCategory': _selectedCategory,
        'locationName': _selectedBuilding!.name,
        'locationCoords': GeoPoint(
          _selectedBuilding!.center.latitude,
          _selectedBuilding!.center.longitude,
        ),
        'timeReported': _timeController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': 0,
        'status': 'active', 
      });

      if (_postType == 'Found Item') {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.update({
          'points': FieldValue.increment(10)
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_itemNameController.text} posted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${e.toString()}')),
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Help the USTP Community find the lost items',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded( child: _buildToggleButton('Lost Item'), ),
                Expanded( child: _buildToggleButton('Found Item'), ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tell others about an item you\'ve ${_postType == 'Lost Item' ? 'lost' : 'found'} on campus',
              style: const TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _itemNameController,
              label: 'Item Name *',
              hint: 'What did you ${_postType == 'Lost Item' ? 'lose' : 'find'}?',
              maxLength: 50,
            ),
            _buildTextField(
              controller: _descriptionController,
              label: 'Detailed Description *',
              hint: 'Provide detailed description...',
              maxLength: 200,
              maxLines: 4,
            ),
            _buildPhotoPicker(),
            const SizedBox(height: 24),
            Text(
              'Category *',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _categories.map((category) {
                return _buildCategoryChip(category);
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // MODIFIED: Fixes for Overflow (Issue 1.1)
            Text(
              'Location on Campus *',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Building>>(
              future: _mapService.getBuildings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error loading buildings: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No buildings found.');
                }
                
                final buildings = snapshot.data!;
                return DropdownButtonFormField<Building>(
                  decoration: const InputDecoration(
                    hintText: 'Select a building or location',
                  ),
                  // MODIFIED (1.1): Added isExpanded to prevent overflow
                  isExpanded: true,
                  value: _selectedBuilding,
                  onChanged: (Building? newValue) {
                    setState(() {
                      _selectedBuilding = newValue;
                    });
                  },
                  items: buildings.map((Building building) {
                    return DropdownMenuItem<Building>(
                      value: building,
                      // MODIFIED (1.1): Wrapped Text in Flexible
                      child: Text(
                        building.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 16),
            _buildTimeField(),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitPost,
                    child: Text('Post $_postType'),
                  ),
          ],
        ),
      ),
    );
  }

  // --- (All helper widgets below are unchanged) ---

  Widget _buildToggleButton(String type) {
    final bool isSelected = _postType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _postType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.lightTextColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(type == 'Lost Item' ? 10 : 0),
            bottomLeft: Radius.circular(type == 'Lost Item' ? 10 : 0),
            topRight: Radius.circular(type == 'Found Item' ? 10 : 0),
            bottomRight: Radius.circular(type == 'Found Item' ? 10 : 0),
          ),
        ),
        child: Center(
          child: Text(
            type,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLength = 100,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Chip(
        label: Text(category),
        backgroundColor: isSelected ? AppTheme.secondaryColor : Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? BorderSide(color: AppTheme.primaryColor, width: 1.5)
              : BorderSide.none,
        ),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.darkTextColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Photos (Optional)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _imageFile!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            GestureDetector(
              onTap: () => _showImageSourceSheet(),
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.lightTextColor),
                  color: Colors.grey.shade100,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppTheme.lightTextColor),
                    SizedBox(height: 4),
                    Text('Add Photo', style: TextStyle(fontSize: 12, color: AppTheme.lightTextColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('From Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When did this happen?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _timeController,
            readOnly: true,
            onTap: _selectDateTime,
            decoration: const InputDecoration(
              hintText: 'e.g. 2 hours ago, this morning, yesterday.',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
        ],
      ),
    );
  }
}