import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';

import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  static const String homePagePath = "/dashboard";
  final bool isAuthenticated;

  const DashboardPage({Key? key, required this.isAuthenticated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alle Tipps',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              BlocBuilder<AuthControllerBloc, AuthControllerState>(
                builder: (context, authState) {
                  if (authState is! AuthControllerLoaded ||
                      authState.signedInUser == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final currentUser = authState.signedInUser!.username;
                  final sortedUsers = List.of(authState.users)
                    ..sort((a, b) => a.rank.compareTo(b.rank));

                  return BlocBuilder<TipControllerBloc, TipControllerState>(
                    builder: (context, tipState) {
                      if (tipState is! TipControllerLoaded) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final tips = tipState.tips;

                      return BlocBuilder<MatchesControllerBloc,
                          MatchesControllerState>(
                        builder: (context, matchState) {
                          if (matchState is! MatchesControllerLoaded) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final matches = List.of(matchState.matches)
                            ..sort((a, b) {
                              final cmp = a.matchDay.compareTo(b.matchDay);
                              return cmp != 0
                                  ? cmp
                                  : a.matchDate.compareTo(b.matchDate);
                            });

                          return BlocBuilder<TeamsControllerBloc,
                              TeamsControllerState>(
                            builder: (context, teamState) {
                              if (teamState is! TeamsControllerLoaded) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final teams = teamState.teams;
                              final grouped = <int, List<CustomMatch>>{};
                              for (final m in matches) {
                                grouped
                                    .putIfAbsent(m.matchDay, () => [])
                                    .add(m);
                              }

                              return Expanded(
                                child: ListView(
                                  children: grouped.entries.map((entry) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Spieltag ${entry.key}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall),
                                        const SizedBox(height: 8),
                                        ...entry.value.map((match) {
                                          final homeTeam = teams.firstWhere(
                                            (t) => t.id == match.homeTeamId,
                                            orElse: () => Team.empty(),
                                          );
                                          final guestTeam = teams.firstWhere(
                                            (t) => t.id == match.guestTeamId,
                                            orElse: () => Team.empty(),
                                          );

                                          final homeFlag = homeTeam != null
                                              ? ClipOval(
                                                  child: Flag.fromString(
                                                    homeTeam.flagCode,
                                                    height: 28,
                                                    width: 28,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const ClipOval(
                                                  child: Icon(Icons.close,
                                                      size: 20,
                                                      color: Colors.grey),
                                                );

                                          final guestFlag = guestTeam != null
                                              ? ClipOval(
                                                  child: Flag.fromString(
                                                    guestTeam.flagCode,
                                                    height: 28,
                                                    width: 28,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const ClipOval(
                                                  child: Icon(Icons.close,
                                                      size: 20,
                                                      color: Colors.grey),
                                                );

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: ExpansionTile(
                                              leading: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipOval(child: homeFlag),
                                                  const SizedBox(width: 4),
                                                  const Text('vs'),
                                                  const SizedBox(width: 4),
                                                  ClipOval(child: guestFlag),
                                                ],
                                              ),
                                              title: Text(
                                                '${homeTeam?.name ?? match?.homeTeamId} vs ${guestTeam?.name ?? match.guestTeamId}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              subtitle: Text(
                                                DateFormat('dd.MM HH:mm')
                                                    .format(match.matchDate),
                                              ),
                                              children: sortedUsers.map((user) {
                                                final userTips =
                                                    tips[user.username] ?? [];
                                                final tip = userTips.firstWhere(
                                                  (t) => t.matchId == match.id,
                                                  orElse: () =>
                                                      Tip.empty(user.username),
                                                );
                                                return ListTile(
                                                  tileColor: user.username ==
                                                          currentUser
                                                      ? Colors.yellow[100]
                                                      : null,
                                                  leading: Text('#${user.rank}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall),
                                                  title: Text(user.username),
                                                  subtitle: tip != null
                                                      ? Text(
                                                          '${tip.tipHome}:${tip.tipGuest}'
                                                          '${tip.joker ? ' ⭐' : ''}')
                                                      : const Text('Kein Tipp'),
                                                  trailing: tip != null
                                                      ? Text(
                                                          '${tip.points ?? '-'} Pkt')
                                                      : null,
                                                );
                                              }).toList(),
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
