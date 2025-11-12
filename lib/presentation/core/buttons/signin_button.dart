import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:routemaster/routemaster.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Anmelden',
      child: FancyIconButton(
        icon: Icons.login,
        callback: () {
          Routemaster.of(context).push('/sign-in');
        },
        backgroundColor: theme.colorScheme.primary,
        hoverColor: Colors.green,
        borderColor: Colors.green,
      ),
    );
  }
}
