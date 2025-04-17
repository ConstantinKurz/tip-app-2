import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web/constants.dart';

class CustomTimePickerField extends StatefulWidget {
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay?> onTimeChanged;
  final String? Function(String?)? hourValidator;
  final String? Function(String?)? minuteValidator;

  const CustomTimePickerField({
    Key? key,
    this.initialTime,
    required this.onTimeChanged,
    this.hourValidator,
    this.minuteValidator,
  }) : super(key: key);

  @override
  _CustomTimePickerFieldState createState() => _CustomTimePickerFieldState();
}

class _CustomTimePickerFieldState extends State<CustomTimePickerField> {
  TimeOfDay? _selectedTime;
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _hourController.text = _selectedTime?.hour.toString().padLeft(2, '0') ?? '';
    _minuteController.text =
        _selectedTime?.minute.toString().padLeft(2, '0') ?? '';
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            controller: _hourController,
            decoration: const InputDecoration(
              labelText: 'Stunde',
              hintText: 'HH',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: _validateHour,
            onChanged: (value) {
              _updateTime();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            controller: _minuteController,
            decoration: const InputDecoration(
              labelText: 'Minute',
              hintText: 'mm',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: _validateMinute,
            onChanged: (value) {
              _updateTime();
            },
          ),
        ),
      ],
    );
  }

  String? _validateHour(String? value) {
    if (value == null || value.isEmpty) {
      return 'Eingabe 30fehlt';
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 23) {
      return '[0-23]';
    }
    return null;
  }

  String? _validateMinute(String? value) {
    if (value == null || value.isEmpty) {
      return 'Eingabe fehtl';
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 59) {
      return '[0-59]';
    }
    return null;
  }

  void _updateTime() {
    int? hour = int.tryParse(_hourController.text);
    int? minute = int.tryParse(_minuteController.text);

    if (hour != null && minute != null) {
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
        widget.onTimeChanged(_selectedTime);
      } else {
        widget.onTimeChanged(null); // Ungültige Eingabe
      }
    } else {
      widget.onTimeChanged(null); // Leere Eingabe
    }
  }
}
