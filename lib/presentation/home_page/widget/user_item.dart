import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/user.dart'; // Import your AppUser model
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';

class UserItem extends StatelessWidget {
  final AppUser user;

  const UserItem({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: themeData.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benutzername: ${user.username}',
            style: themeData.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Email: ${user.email}',
            style: themeData.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Rang: ${user.rank}',
            style: themeData.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Punkte: ${user.score}',
            style: themeData.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FancyIconButton(
                icon: Icons.edit,
                backgroundColor: themeData.colorScheme.onPrimary,
                hoverColor: primaryDark,
                borderColor: primaryDark,
                callback: () {
                  // TODO: Implement edit user functionality
                },
              ),
              const SizedBox(width: 8.0),
              FancyIconButton(
                icon: Icons.delete,
                backgroundColor: themeData.colorScheme.onPrimary,
                hoverColor: Colors.red,
                borderColor: Colors.red,
                callback: () {
                  // TODO: Implement delete user functionality
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
