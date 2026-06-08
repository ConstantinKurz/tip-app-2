import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/presentation/core/buttons/icon_button.dart';
import 'package:flutter_web/presentation/admin_page/widget/user_item.dart';
import 'package:flutter_web/domain/usecases/recalculate_match_tips_usecase.dart';
import 'package:flutter_web/injections.dart';
import 'package:routemaster/routemaster.dart';

class UserList extends StatefulWidget {
  final List<AppUser> users;
  final List<CustomMatch> matches;
  final List<Team> teams;
  const UserList({
    Key? key,
    required this.users,
    required this.matches,
    required this.teams,
  }) : super(key: key);

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  String _searchText = '';
  bool _isRecalculating = false;

  Future<void> _recalculateAllStatistics() async {
    setState(() => _isRecalculating = true);

    try {
      final useCase = sl<RecalculateMatchTipsUseCase>();
      final result = await useCase.recalculateAllUserStatistics();

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fehler: $failure'),
                backgroundColor: Colors.red,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rangliste neu berechnet!'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecalculating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<AppUser> filteredUsers = widget.users.where((user) {
      // Erstellen eines Strings, der den Benutzernamen enthält
      final username = user.name.toLowerCase();
      // Aufteilen des Suchtextes in einzelne Begriffe
      final searchTerms = _searchText.toLowerCase().split(' ');
      // Prüfen, ob alle Suchbegriffe im Benutzernamen enthalten sind
      bool allTermsMatch = true;
      for (final term in searchTerms) {
        if (!username.contains(term)) {
          allTermsMatch = false;
          break;
        }
      }
      // Benutzer zur Liste hinzufügen, wenn alle Suchbegriffe übereinstimmen
      return allTermsMatch;
    }).toList();

    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final double containerWidth =
        isMobile ? screenWidth * 0.95 : screenWidth * 0.4;
    final double searchFieldWidth =
        isMobile ? screenWidth * 0.3 : screenWidth * 0.1;

    return Center(
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipper', style: themeData.textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: TextField(
                                cursorColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Suche',
                                  prefixIcon: Icon(Icons.search),
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (text) {
                                  setState(() {
                                    _searchText = text;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Rangliste neu berechnen',
                            child: IconButton(
                              onPressed: _isRecalculating
                                  ? null
                                  : _recalculateAllStatistics,
                              icon: _isRecalculating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FancyIconButton(
                            backgroundColor:
                                themeData.colorScheme.primaryContainer,
                            hoverColor: primaryDark,
                            borderColor: primaryDark,
                            icon: Icons.add,
                            callback: () => _showAddUsersDialog(context),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text('Tipper', style: themeData.textTheme.headlineLarge),
                      const Spacer(),
                      // Suchleiste
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        width: searchFieldWidth,
                        child: TextField(
                          cursorColor: Colors.white,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Suche',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _searchText = text;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Recalculate Statistics Button
                      Tooltip(
                        message: 'Rangliste neu berechnen',
                        child: IconButton(
                          onPressed:
                              _isRecalculating ? null : _recalculateAllStatistics,
                          icon: _isRecalculating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FancyIconButton(
                          backgroundColor:
                              themeData.colorScheme.primaryContainer,
                          hoverColor: primaryDark,
                          borderColor: primaryDark,
                          icon: Icons.add,
                          callback: () => _showAddUsersDialog(context)),
                    ],
                  ),
            const SizedBox(height: 16.0),
            Expanded(
                child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return UserItem(user: user, teams: widget.teams);
              },
            )),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  void _showAddUsersDialog(BuildContext context) {
    Routemaster.of(context).push('/admin/user/create');
  }
}
