import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

class CustomDatePickerField extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateChanged;

  const CustomDatePickerField({
    Key? key,
    this.initialDate,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  _CustomDatePickerFieldState createState() => _CustomDatePickerFieldState();
}

class _CustomDatePickerFieldState extends State<CustomDatePickerField> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate =
            await showCustomDatePicker(context, _selectedDate);
        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
          widget.onDateChanged(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Datum',
          hintText: 'Datum auswählen',
        ),
        child: Text(_selectedDate != null
            ? '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}'
            : 'Kein Datum ausgewählt', style: const TextStyle(color: Colors.white),),
      ),
    );
  }

  Future<DateTime?> showCustomDatePicker(
      BuildContext context, DateTime? initialDate) async {
    DateTime? selectedDate;
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: 300,
            height: 350,
            child: CalendarDatePicker(
              initialDate: initialDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              onDateChanged: (DateTime date) {
                selectedDate = date;
              },
            ),
          ),
          actions: <Widget>[
            CustomButton(
              buttonText: 'Auswählen',
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              borderColor: primaryDark,
              hoverColor: primaryDark,
              callback: () {
                Navigator.of(context).pop(selectedDate);
              },
            ),
            CustomButton(
              buttonText: 'Abbrechen',
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              borderColor: primaryDark,
              hoverColor: primaryDark,
              callback: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
