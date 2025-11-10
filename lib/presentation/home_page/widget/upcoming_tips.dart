import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_card/modern_tip_card.dart';
import 'package:routemaster/routemaster.dart';

class UpcomingTipSection extends StatelessWidget {
  final String userId;

  const UpcomingTipSection({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      builder: (context, matchState) {
        return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
          builder: (context, teamState) {
            return BlocBuilder<TipControllerBloc, TipControllerState>(
              builder: (context, tipState) {
                if (matchState is MatchesControllerLoaded &&
                    teamState is TeamsControllerLoaded &&
                    tipState is TipControllerLoaded) {
                  
                  final matches = matchState.matches;
                  final teams = teamState.teams;
                  final tips = tipState.tips;

                  // Die 3 Spiele, die zeitlich am nächsten zu "jetzt" sind
                  final now = DateTime.now();
                  final sortedMatches = matches.toList()
                    ..sort((a, b) {
                      final diffA = (a.matchDate.difference(now)).abs();
                      final diffB = (b.matchDate.difference(now)).abs();
                      return diffA.compareTo(diffB);
                    });
                  
                  final closestMatches = sortedMatches.take(3).toList();

                  if (closestMatches.isEmpty) {
                    return _buildEmptyState(context, themeData);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Aktuelle Spiele",
                            style: themeData.textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: () {
                              Routemaster.of(context).push('/tips');
                            },
                            child: Text(
                              'Alle Tipps anzeigen',
                              style: TextStyle(
                                color: themeData.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Spiele-Cards
                      ...closestMatches.map((match) {
                        final homeTeam = teams.firstWhere(
                          (team) => team.id == match.homeTeamId,
                        );
                        final guestTeam = teams.firstWhere(
                          (team) => team.id == match.guestTeamId,
                        );
                        
                        final userTips = tips[userId] ?? <Tip>[];
                        final tip = userTips.firstWhere(
                          (t) => t.matchId == match.id,
                          orElse: () => Tip.empty(userId),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TipCard(
                            userId: userId,
                            match: match,
                            homeTeam: homeTeam,
                            guestTeam: guestTeam,
                            tip: tip,
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aktuelle Spiele",
          style: themeData.textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 48,
                  color: themeData.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Keine Spiele verfügbar',
                  style: themeData.textTheme.bodyLarge?.copyWith(
                    color: themeData.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
