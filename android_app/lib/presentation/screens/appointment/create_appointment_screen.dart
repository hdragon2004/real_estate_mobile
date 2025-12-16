import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/repositories/appointment_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final int? propertyId;
  final String? propertyTitle;

  const CreateAppointmentScreen({
    super.key,
    this.propertyId,
    this.propertyTitle,
  });

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _attendeesController = TextEditingController();
  final AppointmentRepository _repository = AppointmentRepository();

  DateTime? _startDateTime;
  int _reminderMinutes = 60;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền tiêu đề nếu có propertyTitle
    if (widget.propertyTitle != null) {
      _titleController.text = 'Xem nhà: ${widget.propertyTitle}';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _attendeesController.dispose();
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
      _startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Chọn thời gian';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }

  List<String> _parseAttendees(String value) {
    return value
        .split(RegExp(r'[;,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final attendees = _parseAttendees(_attendeesController.text);

      await _repository.createAppointment(
        title: _titleController.text.trim(),
        startTime: _startDateTime!.toUtc(),
        reminderMinutes: _reminderMinutes,
        description: _descriptionController.text,
        location: _locationController.text,
        attendeeEmails: attendees,
        propertyId: widget.propertyId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tạo lịch hẹn thành công')));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tạo lịch hẹn thất bại: $e')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo lịch hẹn')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề cuộc hẹn',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Địa điểm'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _attendeesController,
                    decoration: const InputDecoration(
                      labelText:
                          'Người tham dự (email, cách nhau bởi dấu phẩy)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Thời gian', style: AppTextStyles.h6),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _pickStartDateTime,
                    child: Text(
                      _formatDateTime(_startDateTime),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Nhắc trước', style: AppTextStyles.h6),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _reminderMinutes,
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  Navigator.pop(context, false);
                                },
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
