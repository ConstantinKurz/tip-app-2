import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';

class TipScoreField extends StatelessWidget {
  final TextEditingController controller;
  final String scoreType; // 'home' oder 'guest'
  final String userId;
  final String matchId;
  final bool readOnly;

  const TipScoreField({
    Key? key,
    required this.controller,
    required this.scoreType,
    required this.userId,
    required this.matchId,
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
                    final bloc = context.read<TipFormBloc>();
                    final parsed = int.tryParse(value);
                    bloc.add(
                      TipFormFieldUpdatedEvent(
                        matchId: matchId,
                        userId: userId,
                        tipHome: scoreType == 'home' ? parsed : state.tipHome,
                        tipGuest:
                            scoreType == 'guest' ? parsed : state.tipGuest,
                        joker: state.joker,
                        matchDay: state.matchDay,
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}
