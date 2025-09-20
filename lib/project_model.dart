import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String? id;
  final String name;
  final String description;
  final String venueType; // gedung, lapangan, outdoor, dll
  final String venueName; // nama gedung/tempat
  final String address;
  final String city;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  ProjectModel({
    this.id,
    required this.name,
    required this.description,
    required this.venueType,
    required this.venueName,
    required this.address,
    required this.city,
    this.startDate,
    this.endDate,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  // Convert from Firestore
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      venueType: data['venueType'] ?? '',
      venueName: data['venueName'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      startDate: data['startDate'] != null 
          ? (data['startDate'] as Timestamp).toDate() 
          : null,
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'venueType': venueType,
      'venueName': venueName,
      'address': address,
      'city': city,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }

  // Copy with method for updates
  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? venueType,
    String? venueName,
    String? address,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      venueType: venueType ?? this.venueType,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Venue type getter untuk display
  String get venueTypeDisplayName {
    switch (venueType) {
      case 'indoor_hall':
        return 'Gedung/Hall Indoor';
      case 'outdoor_field':
        return 'Lapangan Outdoor';
      case 'conference_room':
        return 'Ruang Konferensi';
      case 'auditorium':
        return 'Auditorium';
      case 'stadium':
        return 'Stadion';
      case 'park':
        return 'Taman/Area Terbuka';
      case 'hotel':
        return 'Hotel';
      case 'other':
        return 'Lainnya';
      default:
        return venueType;
    }
  }

  // Venue type options
  static List<Map<String, String>> get venueTypeOptions => [
    {'value': 'indoor_hall', 'label': 'Gedung/Hall Indoor'},
    {'value': 'outdoor_field', 'label': 'Lapangan Outdoor'},
    {'value': 'conference_room', 'label': 'Ruang Konferensi'},
    {'value': 'auditorium', 'label': 'Auditorium'},
    {'value': 'stadium', 'label': 'Stadion'},
    {'value': 'park', 'label': 'Taman/Area Terbuka'},
    {'value': 'hotel', 'label': 'Hotel'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  // Get full location string
  String get fullLocation => '$venueName, $address, $city';

  // Get date range display
  String get dateRangeDisplay {
    if (startDate == null) return 'Tanggal belum ditentukan';
    
    String start = '${startDate!.day}/${startDate!.month}/${startDate!.year}';
    if (endDate == null) return start;
    
    String end = '${endDate!.day}/${endDate!.month}/${endDate!.year}';
    return '$start - $end';
  }
}