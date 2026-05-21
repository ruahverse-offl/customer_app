class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? qualifications;
  final String? subSpecialty;
  final String? bio;
  final String? experience;
  final String? education;
  final String? specializations;
  final String? phone;
  final String? imageUrl;
  final double? consultationFee;
  final String? morningStart;
  final String? morningEnd;
  final String? eveningStart;
  final String? eveningEnd;
  final String? morningTimings;
  final String? eveningTimings;
  final bool isActive;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.qualifications,
    this.subSpecialty,
    this.bio,
    this.experience,
    this.education,
    this.specializations,
    this.phone,
    this.imageUrl,
    this.consultationFee,
    this.morningStart,
    this.morningEnd,
    this.eveningStart,
    this.eveningEnd,
    this.morningTimings,
    this.eveningTimings,
    required this.isActive,
  });

  String get initials => name
      .split(' ')
      .where((n) => n.isNotEmpty)
      .map((n) => n[0])
      .take(2)
      .join()
      .toUpperCase();

  String? get displayMorning => morningTimings ?? _formatRange(morningStart, morningEnd);
  String? get displayEvening => eveningTimings ?? _formatRange(eveningStart, eveningEnd);

  static String? _formatRange(String? start, String? end) {
    final s = _fmtTime(start);
    final e = _fmtTime(end);
    if (s == null || e == null) return null;
    return '$s – $e';
  }

  static String? _fmtTime(String? t) {
    if (t == null || t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.length < 2) return t;
    int h = int.tryParse(parts[0]) ?? 0;
    int m = int.tryParse(parts[1]) ?? 0;
    final p = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:${m.toString().padLeft(2, '0')} $p';
  }

  factory Doctor.fromJson(Map<String, dynamic> j) => Doctor(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? '',
        specialty: j['specialty']?.toString() ?? '',
        qualifications: j['qualifications']?.toString(),
        subSpecialty: j['sub_specialty']?.toString(),
        bio: j['bio']?.toString(),
        experience: j['experience']?.toString(),
        education: j['education']?.toString(),
        specializations: j['specializations']?.toString(),
        phone: j['phone']?.toString(),
        imageUrl: j['image_url']?.toString(),
        consultationFee: j['consultation_fee'] != null
            ? double.tryParse(j['consultation_fee'].toString())
            : null,
        morningStart: j['morning_start']?.toString(),
        morningEnd: j['morning_end']?.toString(),
        eveningStart: j['evening_start']?.toString(),
        eveningEnd: j['evening_end']?.toString(),
        morningTimings: j['morning_timings']?.toString(),
        eveningTimings: j['evening_timings']?.toString(),
        isActive: j['is_active'] as bool? ?? false,
      );
}
