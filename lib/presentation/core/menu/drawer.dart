import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/auth/auth_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/core/utils/clear_data.dart';
import 'package:flutter_web/core/utils/setup_tournament.dart';
import 'package:flutter_web/core/utils/simulate_group_stage.dart';
import 'package:flutter_web/core/utils/simulate_knockout_stage.dart';
import 'package:flutter_web/presentation/admin_page/admin_page.dart';
import 'package:flutter_web/presentation/core/menu/home_logo.dart';
import 'package:flutter_web/presentation/core/menu/menu_item.dart';
import 'package:routemaster/routemaster.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthControllerBloc, AuthControllerState>(
      builder: (context, authState) {
        bool isAdmin = false;
        bool isAuthenticated = false;

        if (authState is AuthControllerLoaded) {
          isAuthenticated = authState.signedInUser != null;
          isAdmin = authState.signedInUser?.admin ?? false;
        }

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.75,
          backgroundColor: primaryDark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header with logo and close button
                  Row(
                    children: [
                      const HomeLogo(),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: textPrimaryDark, size: 18),
                      )
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Navigation Section
                  if (isAdmin) ...[
                    MenuItem(
                      text: "Admin",
                      inDrawer: true,
                      path: AdminPage.adminPagePath,
                    ),
                    const SizedBox(height: 20),
                  ],


                  // Divider
                  Divider(color: Colors.white.withOpacity(0.3), thickness: 0.5),
                  const SizedBox(height: 20),

                  // Admin Actions Section (only for admins)
                  if (isAdmin) ...[
                    _buildDrawerLabel("Admin Aktionen"),
                    const SizedBox(height: 12),
                    _DrawerActionItem(
                      icon: Icons.spa_outlined,
                      text: "Seed Data",
                      onTap: () => _handleSeedData(context),
                    ),
                    const SizedBox(height: 12),
                    _DrawerActionItem(
                      icon: Icons.group_work,
                      text: "Simulate Gruppenphase",
                      onTap: () => _handleSimulateGroupStage(context),
                    ),
                    const SizedBox(height: 12),
                    _DrawerActionItem(
                      icon: Icons.play_arrow_sharp,
                      text: "Simulate K.O.-Phase",
                      onTap: () => _handleSimulateKnockoutStage(context),
                    ),
                    const SizedBox(height: 12),
                    _DrawerActionItem(
                      icon: Icons.delete_outline,
                      text: "Daten löschen",
                      onTap: () => _handleClearData(context),
                      isDestructive: true,
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withOpacity(0.3), thickness: 0.5),
                    const SizedBox(height: 20),
                  ],

                  // User Actions Section
                  _buildDrawerLabel("Konto"),
                  const SizedBox(height: 12),
                  if (isAuthenticated) ...[
                    _DrawerActionItem(
                      icon: Icons.person_outline,
                      text: "Profil",
                      onTap: () {
                        Navigator.of(context).pop();
                        Routemaster.of(context).push('/profile');
                      },
                    ),
                    const SizedBox(height: 12),
                    _DrawerActionItem(
                      icon: Icons.logout,
                      text: "Abmelden",
                      onTap: () {
                        Navigator.of(context).pop();
                        context.read<AuthBloc>().add(SignOutPressedEvent());
                      },
                      isDestructive: true,
                    ),
                  ] else
                    _DrawerActionItem(
                      icon: Icons.login,
                      text: "Anmelden",
                      onTap: () {
                        Navigator.of(context).pop();
                        Routemaster.of(context).push('/sign-in');
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildDrawerLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Future<void> _handleSeedData(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await setupTournament();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Testdaten erfolgreich geladen")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Fehler beim Laden: $e")),
        );
      }
    }
  }

  Future<void> _handleSimulateGroupStage(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await simulateGroupStageResults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Gruppenphase simuliert")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Fehler: $e")),
        );
      }
    }
  }

  Future<void> _handleSimulateKnockoutStage(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await simulateKnockoutStageResults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ K.O.-Phase simuliert")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Fehler: $e")),
        );
      }
    }
  }

  Future<void> _handleClearData(BuildContext context) async {
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

    if (confirm == true && context.mounted) {
      Navigator.of(context).pop();
      try {
        await clearDatabaseExceptUser();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Datenbank erfolgreich geleert")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Fehler beim Löschen: $e")),
          );
        }
      }
    }
  }
}

class _DrawerActionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerActionItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade300 : textPrimaryDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
