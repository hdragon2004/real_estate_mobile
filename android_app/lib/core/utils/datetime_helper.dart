
class DateTimeHelper {
  DateTimeHelper._();

  static const int vietnamOffsetHours = 7;

  static DateTime getVietnamNow() {
    final now = DateTime.now();
    final utcNow = now.toUtc();
    
    // Convert UTC về Vietnam time (GMT+7)
    return utcNow.add(Duration(hours: vietnamOffsetHours));
  }

  static DateTime toVietnamTime(DateTime utcDateTime) {
    if (utcDateTime.isUtc) {
      return utcDateTime.add(Duration(hours: vietnamOffsetHours));
    }
    // Nếu đã là local time, convert sang UTC trước rồi mới convert về Vietnam
    final utc = utcDateTime.toUtc();
    return utc.add(Duration(hours: vietnamOffsetHours));
  }

  static DateTime toUtcTime(DateTime vietnamDateTime) {
    if (vietnamDateTime.isUtc) {
      return vietnamDateTime.subtract(Duration(hours: vietnamOffsetHours));
    }
    // Nếu là local time, convert sang UTC
    final utc = vietnamDateTime.toUtc();
    return utc.subtract(Duration(hours: vietnamOffsetHours));
  }

  static String toIso8601String(DateTime dateTime) {
    // Đảm bảo DateTime là Vietnam time
    final vietnamTime = dateTime.isUtc 
        ? toVietnamTime(dateTime) 
        : dateTime;
    
    // Format với timezone offset
    final year = vietnamTime.year.toString().padLeft(4, '0');
    final month = vietnamTime.month.toString().padLeft(2, '0');
    final day = vietnamTime.day.toString().padLeft(2, '0');
    final hour = vietnamTime.hour.toString().padLeft(2, '0');
    final minute = vietnamTime.minute.toString().padLeft(2, '0');
    final second = vietnamTime.second.toString().padLeft(2, '0');
    
    return '$year-$month-${day}T$hour:$minute:$second+07:00';
  }

  static DateTime fromBackendString(String dateTimeString) {
    try {
      final parsed = DateTime.parse(dateTimeString);
      
      // Nếu là UTC, convert về Vietnam time
      if (parsed.isUtc) {
        return toVietnamTime(parsed);
      }
      
      // Nếu đã có timezone info, giữ nguyên
      return parsed;
    } catch (e) {
      // Nếu parse lỗi, trả về thời gian hiện tại
      return getVietnamNow();
    }
  }

  static bool isVietnamTime(DateTime dateTime) {
    return !dateTime.isUtc;
  }
}

