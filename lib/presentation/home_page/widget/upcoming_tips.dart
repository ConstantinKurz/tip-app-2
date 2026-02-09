import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/tip_card/tip_card.dart';
import 'package:routemaster/routemaster.dart';

class UpcomingTipSection extends StatefulWidget {
  final String userId;

  const UpcomingTipSection({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UpcomingTipSection> createState() => _UpcomingTipSectionState();
}

class _UpcomingTipSectionState extends State<UpcomingTipSection> {
  final Map<String, TipFormBloc> _tipFormBlocs = {};
  final Set<int> _statsLoadedForMatchDays = {}; // ✅ NEU: Verhindere doppeltes Laden

  @override
  void dispose() {
    for (var bloc in _tipFormBlocs.values) {
      bloc.close();
    }
    super.dispose();
  }

  TipFormBloc _getTipFormBloc(String matchId) {
    if (!_tipFormBlocs.containsKey(matchId)) {
      _tipFormBlocs[matchId] = sl<TipFormBloc>();
    }
    return _tipFormBlocs[matchId]!;
  }

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

                  // Die 3 nächsten anstehenden Spiele finden
                  final now = DateTime.now();
                  final upcomingMatches = matches.where((match) {
                    final matchEndTime = match.matchDate.add(const Duration(minutes: matchDuration));
                    return matchEndTime.isAfter(now);
                  }).toList();

                  upcomingMatches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
                  final closestMatches = upcomingMatches.take(3).toList();

                  if (closestMatches.isEmpty) {
                    return _buildEmptyState(context, themeData);
                  }

                  // ✅ NEU: Lade Statistiken für alle sichtbaren MatchDays
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    for (final match in closestMatches) {
                      if (!_statsLoadedForMatchDays.contains(match.matchDay)) {
                        context.read<TipControllerBloc>().add(
                              TipUpdateStatisticsEvent(
                                userId: widget.userId,
                                matchDay: match.matchDay,
                              ),
                            );
                        _statsLoadedForMatchDays.add(match.matchDay);
                      }
                    }
                  });

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

                        final userTips = tips[widget.userId] ?? <Tip>[];
                        final tip = userTips.firstWhere(
                          (t) => t.matchId == match.id,
                          orElse: () => Tip.empty(widget.userId),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final tipId = tip.id.isNotEmpty
                                  ? tip.id
                                  : "${widget.userId}_${match.id}";
                              Routemaster.of(context)
                                  .push('/tips-detail/$tipId?from=home');
                            },
                            child: BlocProvider<TipFormBloc>.value(
                              value: _getTipFormBloc(match.id),
                              child: _TipCardInitializer(
                                matchId: match.id,
                                userId: widget.userId,
                                matchDay: match.matchDay,
                                child: TipCard(
                                  userId: widget.userId,
                                  tip: tip,
                                  homeTeam: homeTeam,
                                  guestTeam: guestTeam,
                                  match: match,
                                ),
                              ),
                            ),
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

/// Wrapper widget that initializes TipFormBloc only once
class _TipCardInitializer extends StatefulWidget {
  final String matchId;
  final String userId;
  final int matchDay;
  final Widget child;

  const _TipCardInitializer({
    required this.matchId,
    required this.userId,
    required this.matchDay,
    required this.child,
  });

  @override
  State<_TipCardInitializer> createState() => _TipCardInitializerState();
}

class _TipCardInitializerState extends State<_TipCardInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final bloc = context.read<TipFormBloc>();
      bloc.add(TipFormInitializedEvent(
        matchId: widget.matchId,
        userId: widget.userId,
        matchDay: widget.matchDay,
      ));
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
