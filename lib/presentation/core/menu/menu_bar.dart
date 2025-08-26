import 'package:flutter/material.dart';
import 'package:flutter_web/core/utils/clear_data.dart';
import 'package:flutter_web/core/utils/seed_data.dart';
import 'package:flutter_web/core/utils/single_seed_data.dart';
import 'package:flutter_web/core/utils/three_seed_data.dart';
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/core/buttons/signin_button.dart';
import 'package:flutter_web/presentation/core/buttons/signout_button.dart';
import 'package:flutter_web/presentation/core/buttons/signup_button.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:flutter_web/presentation/dev_page/dev_page.dart';
import 'package:flutter_web/presentation/eco_page/eco_page.dart';

class MyMenuBar extends StatelessWidget {
  final bool isAuthenticated;
  const MyMenuBar({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Container(
      height: 66,
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeData.colorScheme.primaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const HomeLogo(),
          MenuItem(text: "Admin", inDrawer: false, path: AdminPage.adminPagePath),
          MenuItem(text: "Development", inDrawer: false, path: DevPage.devPagePath),
          MenuItem(text: "Ecosystem", inDrawer: false, path: EcoPage.ecoPagePath),
          const Spacer(),

          // Seed Data Button (nur wenn eingeloggt)
          if (isAuthenticated) 
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Seed Data"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await seedTestDataTwentyUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Testdaten erfolgreich geladen")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Fehler beim Laden: $e")),
                  );
                }
              },
            ),

            const SizedBox(width: 8),
          if (isAuthenticated)
            // Clear Data Button (immer sichtbar)
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text("Clear Data"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
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
                      const SnackBar(content: Text("✅ Datenbank erfolgreich geleert")),
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

          isAuthenticated
              ? const SignOutButton(inDrawer: false)
              : const SignInButton(inDrawer: false),
          const SizedBox(width: 10),
          const SignUpButton(inDrawer: false),
        ],
      ),
    );
  }
}
