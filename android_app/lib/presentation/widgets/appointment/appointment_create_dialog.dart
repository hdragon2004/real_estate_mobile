import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/repositories/appointment_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Dialog hiển thị form tạo lịch hẹn
class AppointmentCreateDialog extends StatefulWidget {
  final int propertyId;
  final String propertyTitle;

  const AppointmentCreateDialog({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<AppointmentCreateDialog> createState() =>
      _AppointmentCreateDialogState();

  /// Hiển thị dialog tạo lịch hẹn
  static Future<bool?> show(
    BuildContext context, {
    required int propertyId,
    required String propertyTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentCreateDialog(
        propertyId: propertyId,
        propertyTitle: propertyTitle,
      ),
    );
  }
}

class _AppointmentCreateDialogState extends State<AppointmentCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AppointmentRepository _repository = AppointmentRepository();

  DateTime? _startDateTime;
  int _reminderMinutes = 60;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền tiêu đề
    _titleController.text = 'Xem nhà: ${widget.propertyTitle}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (!mounted) {
      return;
    }

    if (date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime ?? now),
    );

    if (!mounted) {
      return;
    }

    if (time == null) {
      return;
    }

    setState(() {
      // Tạo DateTime local (không phải UTC) để giữ nguyên thời gian user chọn
      _startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      // Đảm bảo là local time (không phải UTC)
      // DateTime constructor mặc định tạo local time nếu không chỉ định isUtc
    });
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Chọn thời gian';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) {
      return;
    }

    if (!form.validate()) {
      return;
    }

    if (_startDateTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _repository.createAppointment(
        title: _titleController.text.trim(),
        startTime: _startDateTime!,
        reminderMinutes: _reminderMinutes,
        propertyId: widget.propertyId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo lịch hẹn thất bại: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Tạo lịch hẹn',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề cuộc hẹn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Mô tả (tùy chọn)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Gap(24),
                    Text(
                      'Thời gian',
                      style: AppTextStyles.h6,
                    ),
                    const Gap(8),
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : _pickStartDateTime,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today),
                          const Gap(8),
                          Text(
                            _formatDateTime(_startDateTime),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),
                    Text(
                      'Nhắc trước',
                      style: AppTextStyles.h6,
                    ),
                    const Gap(8),
                    DropdownButtonFormField<int>(
                      initialValue: _reminderMinutes,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15 phút')),
                        DropdownMenuItem(value: 30, child: Text('30 phút')),
                        DropdownMenuItem(value: 60, child: Text('1 giờ')),
                        DropdownMenuItem(value: 120, child: Text('2 giờ')),
                        DropdownMenuItem(value: 1440, child: Text('1 ngày')),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _reminderMinutes = value;
                                });
                              }
                            },
                    ),
                    const Gap(32),
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.pop(context, false);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Tạo lịch hẹn'),
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

