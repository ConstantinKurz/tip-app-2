import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
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
  final Set<int> _statsLoadedForMatchDays = {};

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
    final screenWidth = MediaQuery.of(context).size.width;
    const matchDuration = 120;

    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      builder: (context, matchState) {
        return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
          builder: (context, teamState) {
            return BlocBuilder<TipControllerBloc, TipControllerState>(
              // Nur rebuilden wenn sich Tips ändern oder State-Typ wechselt
              buildWhen: (previous, current) {
                // Bei State-Typ-Wechsel immer rebuilden
                if (previous.runtimeType != current.runtimeType) return true;
                // Bei Loaded-States nur rebuilden wenn sich Tips ändern (nicht Stats)
                if (previous is TipControllerLoaded && current is TipControllerLoaded) {
                  return previous.tips != current.tips;
                }
                return true;
              },
              builder: (context, tipState) {
                if (matchState is MatchesControllerLoading ||
                    teamState is TeamsControllerLoading ||
                    tipState is TipControllerLoading ||
                    tipState is TipControllerInitial) {
                  return _buildLoadingState(context, themeData);
                }

                if (matchState is MatchesControllerFailure ||
                    teamState is TeamsControllerFailureState ||
                    tipState is TipControllerFailure) {
                  return _buildErrorState(context, themeData);
                }

                if (matchState is! MatchesControllerLoaded ||
                    teamState is! TeamsControllerLoaded ||
                    tipState is! TipControllerLoaded) {
                  return _buildEmptyState(context, themeData);
                }

                final matches = matchState.matches;
                final teams = teamState.teams;
                final tips = tipState.tips;

                if (matches.isEmpty || teams.isEmpty) {
                  return _buildEmptyState(context, themeData);
                }

                final now = DateTime.now();
                final upcomingMatches = matches
                    .where((match) {
                      final matchEndTime = match.matchDate
                          .add(const Duration(minutes: matchDuration));
                      return matchEndTime.isAfter(now);
                    })
                    .toList();

                upcomingMatches.sort((a, b) => a.matchDate.compareTo(b.matchDate));
                final closestMatches = upcomingMatches.take(3).toList();

                if (closestMatches.isEmpty) {
                  return _buildEmptyState(context, themeData);
                }

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

                    // ✅ Spiele-Cards mit Navigation
                    ...closestMatches.asMap().entries.map((entry) {
                      final index = entry.key;
                      final match = entry.value;

                      final homeTeam = teams.firstWhere(
                        (team) => team.id == match.homeTeamId,
                        orElse: () => teams.first,
                      );
                      final guestTeam = teams.firstWhere(
                        (team) => team.id == match.guestTeamId,
                        orElse: () => teams.first,
                      );

                      final userTips = tips[widget.userId] ?? [];
                      final tip = userTips.firstWhere(
                        (t) => t.matchId == match.id,
                        orElse: () => Tip.empty(widget.userId),
                      );

                      // ✅ Erstelle tipId wie in tip_page.dart
                      final tipId = tip.id.isNotEmpty
                          ? tip.id
                          : "${widget.userId}_${match.id}";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth * 0.6,
                          ),
                          // ✅ Navigation mit InkWell
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // Navigation zur Detail-Ansicht
                              Routemaster.of(context).push(
                                '/tips-detail/$tipId?from=home&returnIndex=$index',
                              );
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
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aktuelle Spiele",
          style: themeData.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aktuelle Spiele",
          style: themeData.textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: const Text(
            '❌ Fehler beim Laden der Spiele',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
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
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: themeData.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            'Keine kommenden Spiele',
            style: themeData.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _TipCardInitializer extends StatefulWidget {
  final String matchId;
  final String userId;
  final int matchDay;
  final Widget child;

  const _TipCardInitializer({
    Key? key,
    required this.matchId,
    required this.userId,
    required this.matchDay,
    required this.child,
  }) : super(key: key);

  @override
  State<_TipCardInitializer> createState() => _TipCardInitializerState();
}

class _TipCardInitializerState extends State<_TipCardInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true; // Vor dem Dispatch setzen um Mehrfachausführung zu verhindern

      final bloc = context.read<TipFormBloc>();
      final controllerBloc = context.read<TipControllerBloc>();
      final tipState = controllerBloc.state;

      bloc.add(TipFormInitializedEvent(
        matchId: widget.matchId,
        userId: widget.userId,
        matchDay: widget.matchDay,
      ));

      // Tip-Daten aus TipControllerBloc an TipFormBloc übergeben
      if (tipState is TipControllerLoaded) {
        final userTips = tipState.tips[widget.userId] ?? [];
        final tip = userTips.firstWhere(
          (t) => t.matchId == widget.matchId,
          orElse: () => Tip.empty(widget.userId),
        );

        bloc.add(TipFormExternalUpdateEvent(
          matchId: widget.matchId,
          matchDay: widget.matchDay,
          tipHome: tip.tipHome,
          tipGuest: tip.tipGuest,
          joker: tip.joker,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TipControllerBloc, TipControllerState>(
      listenWhen: (previous, current) {
        // Nur reagieren wenn sich Tips ändern
        if (previous is TipControllerLoaded && current is TipControllerLoaded) {
          return previous.tips != current.tips;
        }
        return current is TipControllerLoaded;
      },
      listener: (context, tipState) {
        if (tipState is TipControllerLoaded) {
          final formBloc = context.read<TipFormBloc>();
          final userTips = tipState.tips[widget.userId] ?? [];
          final tip = userTips.firstWhere(
            (t) => t.matchId == widget.matchId,
            orElse: () => Tip.empty(widget.userId),
          );

          formBloc.add(TipFormExternalUpdateEvent(
            matchId: widget.matchId,
            matchDay: widget.matchDay,
            tipHome: tip.tipHome,
            tipGuest: tip.tipGuest,
            joker: tip.joker,
          ));
        }
      },
      child: widget.child,
    );
  }
}
