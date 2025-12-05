import 'package:flutter/material.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:routemaster/routemaster.dart';

class UserButton extends StatelessWidget {
  const UserButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Profil',
      child: FancyIconButton(
        icon: Icons.person,
        callback: () {
          Routemaster.of(context).push('/profile');
        },
        backgroundColor: theme.colorScheme.primary,
        hoverColor: Colors.blue,
        borderColor: Colors.blue,
      ),
    );
  }
}