import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Abmelden',
      child: FancyIconButton(
        icon: Icons.logout,
        callback: () {
          context.read<AuthBloc>().add(SignOutPressedEvent());
        },
        backgroundColor: theme.colorScheme.primaryContainer,
        hoverColor: Colors.red,
        borderColor: Colors.red,
      ),
    );
  }
}
