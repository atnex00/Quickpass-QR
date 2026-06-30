class Validators {
  static String? employeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Must be exactly 6 digits';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? timeRange(String? startTime, String? endTime) {
    if (startTime == null || endTime == null) return null;
    if (startTime.compareTo(endTime) >= 0) {
      return 'End time must be after start time';
    }
    return null;
  }
}
