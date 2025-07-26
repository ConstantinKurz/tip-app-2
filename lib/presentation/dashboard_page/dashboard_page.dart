import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';

import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  static const String homePagePath = "/dashboard";
  final bool isAuthenticated;

  const DashboardPage({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BlocBuilder<AuthControllerBloc, AuthControllerState>(
          builder: (context, authState) {
            if (authState is! AuthControllerLoaded || authState.signedInUser == null) {
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

                return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
                  builder: (context, matchState) {
                    if (matchState is! MatchesControllerLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final matches = List.of(matchState.matches)
                      ..sort((a, b) => a.matchDate.compareTo(b.matchDate));

                    return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
                      builder: (context, teamState) {
                        if (teamState is! TeamsControllerLoaded) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final teams = teamState.teams;

                        Team getTeamById(String id) {
                          return teams.firstWhere((team) => team.id == id, orElse: () => Team.empty());
                        }

                        Tip getTipForUserMatch(AppUser user, CustomMatch match) {
                          final userTips = tips[user.username] ?? [];
                          return userTips.firstWhere(
                            (t) => t.matchId == match.id,
                            orElse: () => Tip.empty(user.username),
                          );
                        }

                        return PageView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            final homeTeam = getTeamById(match.homeTeamId);
                            final guestTeam = getTeamById(match.guestTeamId);

                            return Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Matchinfo
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${homeTeam.name} vs ${guestTeam.name}',
                                              style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 4),
                                          Text(DateFormat('dd.MM HH:mm').format(match.matchDate),
                                              style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    const Divider(),
                                    // Tipps aller User
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: sortedUsers.length,
                                        itemBuilder: (context, userIndex) {
                                          final user = sortedUsers[userIndex];
                                          final tip = getTipForUserMatch(user, match);
                                          final isCurrent = user.username == currentUser;

                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: isCurrent ? Colors.grey[900] : Colors.grey[800],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: Text('#${user.rank} ${user.username}',
                                                  style: const TextStyle(color: Colors.white)),
                                              subtitle: Text('${tip.tipHome}:${tip.tipGuest} ${tip.joker ? "⭐" : ""}',
                                                  style: const TextStyle(color: Colors.yellow)),
                                              trailing: Text('${tip.points} Pkt',
                                                  style: const TextStyle(color: Colors.greenAccent)),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
