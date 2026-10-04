import 'package:flutter/material.dart';
import 'package:autism_project/services/api_service.dart';
import 'package:autism_project/services/token_storage.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<dynamic> _doctors = [];
  List<dynamic> _filteredDoctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Available specialties from the data
  List<String> _specialties = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getDoctorList();

      if (result['success'] && mounted) {
        setState(() {
          _doctors = result['data'] ?? [];
          _filteredDoctors = _doctors;

          // Extract unique specialties for filter chips
          final Set<String> specialties = {'All'};
          for (var doctor in _doctors) {
            if (doctor['department'] != null) {
              specialties.add(doctor['department']);
            }
          }
          _specialties = specialties.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load doctors';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final matchesSearch = doctor['doctor_name']?.toLowerCase().contains(query) ?? false;
        final matchesFilter = _selectedFilter == 'All' ||
            (doctor['department'] == _selectedFilter);
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterDoctors();
    });
  }

  // Get a color based on doctor name for avatar
  Color _getDoctorColor(String name) {
    final colors = [
      const Color(0xFF6B5B95),
      const Color(0xFF88B0D3),
      const Color(0xFF957DAD),
      const Color(0xFFE8A2A2),
      const Color(0xFF4A90E2),
      const Color(0xFF50C878),
      const Color(0xFFF4A460),
      const Color(0xFF9B59B6),
    ];

    int index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  // Get initials from doctor name
  String _getInitials(String name) {
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0][0] + parts[1][0];
    } else if (parts.isNotEmpty) {
      return parts[0][0];
    }
    return 'DR';
  }

  // Check if doctor has any available slots
  bool _hasAvailableSlots(List<dynamic> slots) {
    if (slots.isEmpty) return false;
    return slots.any((slot) => slot['is_booked'] == false);
  }

  // Get available slots count
  int _getAvailableSlotsCount(List<dynamic> slots) {
    if (slots.isEmpty) return 0;
    return slots.where((slot) => slot['is_booked'] == false).length;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;

    return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchDoctors,
            color: const Color(0xFF6B5B95),
            child: Column(
              children: [
                // Header with Search
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Specialists',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : (isTablet ? 28 : 32),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect with experienced professionals',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name',
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: isSmallScreen ? 12 : 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter Chips
                if (_specialties.length > 1)
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _specialties.length,
                      itemBuilder: (context, index) {
                        final specialty = _specialties[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                              specialty,
                              _selectedFilter == specialty
                          ),
                        );
                      },
                    ),
                  ),

                // Doctors List or Loading/Error State
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B5B95),
                    ),
                  )
                      : _errorMessage != null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDoctors,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B5B95),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                      : _filteredDoctors.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No doctors found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    itemCount: _filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _filteredDoctors[index];
                      final doctorName = doctor['doctor_name'] ?? 'Unknown Doctor';
                      final specialty = doctor['department'] ?? 'General';
                      final slots = doctor['slots'] ?? [];
                      final hasAvailableSlots = _hasAvailableSlots(slots);
                      final availableSlotsCount = _getAvailableSlotsCount(slots);
                      final doctorColor = _getDoctorColor(doctorName);
                      final initials = _getInitials(doctorName);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Doctor Avatar
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: doctorColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: doctorColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Doctor Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctorName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        specialty,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (slots.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.event_available,
                                              color: hasAvailableSlots ? Colors.green : Colors.grey,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$availableSlotsCount available slots',
                                              style: TextStyle(
                                                color: hasAvailableSlots ? Colors.green : Colors.grey,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                // Availability Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasAvailableSlots
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hasAvailableSlots ? 'Available' : 'No Slots',
                                    style: TextStyle(
                                      color: hasAvailableSlots
                                          ? Colors.green
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _showDoctorDetails(context, doctor, doctorColor, initials);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6B5B95),
                                      side: const BorderSide(color: Color(0xFF6B5B95)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('View Profile'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: hasAvailableSlots
                                        ? () {
                                      _showBookingDialog(context, doctor);
                                    }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B5B95),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: Colors.grey.shade300,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Book'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        )
        );
    }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {
        _applyFilter(label);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF6B5B95).withOpacity(0.2),
      checkmarkColor: const Color(0xFF6B5B95),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6B5B95) : Colors.grey.shade700,
      ),
    );
  }

  void _showDoctorDetails(BuildContext context, Map<String, dynamic> doctor, Color doctorColor, String initials) {
    final doctorName = doctor['doctor_name'] ?? 'Unknown Doctor';
    final specialty = doctor['department'] ?? 'General';
    final slots = doctor['slots'] ?? [];
    final hasAvailableSlots = _hasAvailableSlots(slots);
    final availableSlots = slots.where((slot) => slot['is_booked'] == false).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: doctorColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: doctorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            specialty,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.work_outline, specialty),
                _buildInfoRow(Icons.event_available, '${slots.length} total slots'),
                _buildInfoRow(
                    Icons.access_time,
                    '${availableSlots.length} available slots'
                ),
                if (availableSlots.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Available Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = availableSlots[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.access_time, color: Color(0xFF6B5B95)),
                            title: Text('${slot['date']}'),
                            subtitle: Text(
                                '${slot['start_time_display']} - ${slot['end_time_display']}'
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmBooking(context, slot['id'], doctorName);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B5B95),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Book'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B5B95), size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Map<String, dynamic> doctor) {
    final doctorName = doctor['doctor_name'] ?? 'Unknown Doctor';
    final slots = doctor['slots'] ?? [];
    final availableSlots = slots.where((slot) => slot['is_booked'] == false).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Appointment Slot',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Dr. $doctorName',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            if (availableSlots.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No available slots at the moment'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableSlots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Date: ${slot['date']}'),
                      subtitle: Text(
                          '${slot['start_time_display']} - ${slot['end_time_display']}'
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmBooking(context, slot['id'], doctorName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B5B95),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Select'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmBooking(BuildContext context, int slotId, String doctorName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time,
              color: Color(0xFF6B5B95),
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Book appointment with',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Dr. $doctorName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please confirm your booking',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              await _bookAppointment(context, slotId, doctorName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5B95),
            ),
            child: const Text('Confirm',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Future<void> _bookAppointment(BuildContext context, int slotId, String doctorName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B5B95)),
      ),
    );

    try {
      final result = await ApiService.bookAppointment(slotId: slotId);

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (result['success'] && context.mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Success!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'Appointment booked with Dr. $doctorName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Color(0xFF6B5B95), size: 16),
                      SizedBox(width: 8),
                      Text('We\'ll send you a reminder'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
              onPressed: () {
            // First close the success dialog
            Navigator.pop(context);
        // Then close any bottom sheets that might be open
        Navigator.popUntil(context, (route) {
          return route.isFirst;
        });
        // Refresh doctors list
        _fetchDoctors();
      },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else if (context.mounted) {
        // Show error dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to book appointment'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}