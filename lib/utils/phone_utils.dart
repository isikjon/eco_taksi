class PhoneUtils {
  static String normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    // Извлекаем только цифры из номера
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 996, добавляем +
    if (digitsOnly.startsWith('996')) {
      return '+$digitsOnly';
    }
    
    // Если номер начинается с 9 (без 996), добавляем +996
    if (digitsOnly.startsWith('9') && digitsOnly.length == 9) {
      return '+996$digitsOnly';
    }
    
    // Если номер уже содержит 996 в начале, просто добавляем +
    if (digitsOnly.length >= 12 && digitsOnly.startsWith('996')) {
      return '+$digitsOnly';
    }
    
    // Если номер уже содержит +, убираем все пробелы и возвращаем
    if (phoneNumber.startsWith('+')) {
      return phoneNumber.replaceAll(RegExp(r'\s'), '');
    }
    
    return phoneNumber;
  }
  
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    String normalized = normalizePhoneNumber(phoneNumber);
    
    // Форматируем для отображения: +996 123 456 789 (12 цифр)
    if (normalized.startsWith('+996') && normalized.length == 13) {
      String digits = normalized.substring(4);
      return '+996 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    
    return normalized;
  }
  
  // Метод для получения номера без + для API запросов
  static String getPhoneForApi(String phoneNumber) {
    String normalized = normalizePhoneNumber(phoneNumber);
    // Убираем + для API запросов
    return normalized.startsWith('+') ? normalized.substring(1) : normalized;
  }
}
