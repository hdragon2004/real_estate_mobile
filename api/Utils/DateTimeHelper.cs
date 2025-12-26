using System;

namespace RealEstateHubAPI.Utils
{
    public static class DateTimeHelper
    {
        private static TimeZoneInfo? _vietnamTimeZone;

        private static TimeZoneInfo GetVietnamTimeZone()
        {
            if (_vietnamTimeZone != null)
            {
                return _vietnamTimeZone;
            }

            try
            {
                // Windows: "SE Asia Standard Time"
                _vietnamTimeZone = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
            }
            catch (TimeZoneNotFoundException)
            {
                try
                {
                    // Linux/macOS: "Asia/Ho_Chi_Minh"
                    _vietnamTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
                }
                catch (TimeZoneNotFoundException)
                {
                    // Fallback: tạo custom timezone GMT+7
                    _vietnamTimeZone = TimeZoneInfo.CreateCustomTimeZone(
                        "Vietnam Standard Time",
                        TimeSpan.FromHours(7),
                        "Vietnam Standard Time",
                        "Vietnam Standard Time"
                    );
                }
            }

            return _vietnamTimeZone;
        }

        public static DateTime GetVietnamNow()
        {
            var vietnamTimeZone = GetVietnamTimeZone();
            var utcNow = DateTime.UtcNow;
            return TimeZoneInfo.ConvertTimeFromUtc(utcNow, vietnamTimeZone);
        }

        public static DateTime ToVietnamTime(DateTime utcDateTime)
        {
            if (utcDateTime.Kind == DateTimeKind.Unspecified)
            {
                // Nếu không xác định được kind, giả định là UTC
                var utc = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
                var vietnamTimeZone = GetVietnamTimeZone();
                return TimeZoneInfo.ConvertTimeFromUtc(utc, vietnamTimeZone);
            }

            if (utcDateTime.Kind == DateTimeKind.Utc)
            {
                var vietnamTimeZone = GetVietnamTimeZone();
                return TimeZoneInfo.ConvertTimeFromUtc(utcDateTime, vietnamTimeZone);
            }

            // Nếu đã là local time, trả về nguyên vẹn
            return utcDateTime;
        }

        public static DateTime ToUtcTime(DateTime vietnamDateTime)
        {
            var vietnamTimeZone = GetVietnamTimeZone();
            
            // Nếu DateTime không có Kind, giả định là Vietnam local time
            if (vietnamDateTime.Kind == DateTimeKind.Unspecified)
            {
                var local = DateTime.SpecifyKind(vietnamDateTime, DateTimeKind.Unspecified);
                return TimeZoneInfo.ConvertTimeToUtc(local, vietnamTimeZone);
            }

            if (vietnamDateTime.Kind == DateTimeKind.Local)
            {
                return TimeZoneInfo.ConvertTimeToUtc(vietnamDateTime, vietnamTimeZone);
            }

            // Nếu đã là UTC, trả về nguyên vẹn
            return vietnamDateTime;
        }

        public static bool IsVietnamTime(DateTime dateTime)
        {
            var vietnamTimeZone = GetVietnamTimeZone();
            var offset = vietnamTimeZone.GetUtcOffset(dateTime);
            return offset == TimeSpan.FromHours(7);
        }
    }
}

