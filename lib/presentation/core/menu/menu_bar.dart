import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/core/utils/clear_data.dart';
import 'package:flutter_web/core/utils/seed_data.dart';
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/core/buttons/signin_button.dart';
import 'package:flutter_web/presentation/core/buttons/signout_button.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:flutter_web/presentation/core/buttons/user_button.dart';
import 'package:flutter_web/theme.dart';

class MyMenuBar extends StatelessWidget {
  final bool isAuthenticated;
  const MyMenuBar({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return BlocBuilder<AuthControllerBloc, AuthControllerState>(
      builder: (context, authState) {
        bool isAdmin = false;
        if (authState is AuthControllerLoaded &&
            authState.signedInUser != null) {
          isAdmin = authState.signedInUser?.admin ?? false;

        }
        return Container(
          height: 66,
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeData.colorScheme.primary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const HomeLogo(),
              const SizedBox(width: 16),
              if (isAdmin)
                MenuItem(
                  text: "Admin",
                  inDrawer: false,
                  path: AdminPage.adminPagePath,
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.spa_outlined),
                tooltip: "Seed Data",
                onPressed: () async {
                  try {
                    await seedTestDataTwentyUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("✅ Testdaten erfolgreich geladen")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Fehler beim Laden: $e")),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: "Clear Data",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("⚠️ Achtung"),
                      content: const Text(
                          "Bist du sicher, dass du alle Daten außer deinem eigenen User löschen willst?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Abbrechen"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Ja, löschen"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await clearDatabaseExceptUser();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("✅ Datenbank erfolgreich geleert")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❌ Fehler beim Löschen: $e")),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 12),
                if (isAuthenticated) ...[
                  const UserButton(),
                  const SizedBox(width: 8),
                  const SignOutButton(),
                ] else
                  const SignInButton(),
                  const SizedBox(width: 10),
            ],
          ),
        );
      },
    );
  }
}
