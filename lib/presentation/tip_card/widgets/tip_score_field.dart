import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';

class TipScoreField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController otherController; 
  final String scoreType;
  final String userId;
  final String matchId;
  final int matchDay;
  final bool readOnly;

  const TipScoreField({
    Key? key,
    required this.controller,
    required this.otherController,
    required this.scoreType,
    required this.userId,
    required this.matchId,
    required this.matchDay,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return BlocBuilder<TipFormBloc, TipFormState>(
      builder: (context, state) {
        final isDisabled = state.isTipLimitReached;
        final bool readOnly = this.readOnly || isDisabled;
        
        return SizedBox(
          width: 50,
          child: TextFormField(
            textAlign: TextAlign.center,
            controller: controller,
            readOnly: readOnly,
            style: themeData.textTheme.bodyLarge,
            cursorColor: themeData.colorScheme.onPrimary,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              filled: true,
              fillColor: themeData.colorScheme.primary,
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: themeData.colorScheme.onPrimary),
              ),
            ),
            onChanged: readOnly
                ? null
                : (value) {
                    final currentHome = scoreType == 'home' 
                        ? (value.isEmpty ? null : int.tryParse(value))
                        : (otherController.text.isEmpty ? null : int.tryParse(otherController.text));
                    
                    final currentGuest = scoreType == 'guest' 
                        ? (value.isEmpty ? null : int.tryParse(value))
                        : (otherController.text.isEmpty ? null : int.tryParse(otherController.text));

                    context.read<TipFormBloc>().add(
                      TipFormFieldUpdatedEvent(
                        matchId: matchId,
                        userId: userId,
                        tipHome: currentHome,
                        tipGuest: currentGuest,
                        joker: state.joker,
                        matchDay: matchDay,
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}
