import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/entities/team.dart';
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
    for (final bloc in _tipFormBlocs.values) {
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
    const matchDuration = 120;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
      builder: (context, matchState) {
        return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
          builder: (context, teamState) {
            return BlocBuilder<TipControllerBloc, TipControllerState>(
              buildWhen: (previous, current) {
                if (previous.runtimeType != current.runtimeType) return true;

                if (previous is TipControllerLoaded &&
                    current is TipControllerLoaded) {
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
                final upcomingMatches = matches.where((match) {
                  final matchEndTime = match.matchDate.add(
                    const Duration(minutes: matchDuration),
                  );

                  return matchEndTime.isAfter(now);
                }).toList();

                upcomingMatches.sort(
                  (a, b) => a.matchDate.compareTo(b.matchDate),
                );

                final closestMatches = upcomingMatches.take(3).toList();

                if (closestMatches.isEmpty) {
                  return _buildEmptyState(context, themeData);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

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
                    _UpcomingTipsHeader(
                      isMobile: isMobile,
                      themeData: themeData,
                    ),
                    const SizedBox(height: 16),
                    ...closestMatches.asMap().entries.map((entry) {
                      final index = entry.key;
                      final match = entry.value;

                      final homeTeam = teams.firstWhere(
                        (team) => team.id == match.homeTeamId,
                        orElse: () => Team.empty(),
                      );

                      final guestTeam = teams.firstWhere(
                        (team) => team.id == match.guestTeamId,
                        orElse: () => Team.empty(),
                      );

                      final userTips = tips[widget.userId] ?? [];

                      final tip = userTips.firstWhere(
                        (t) => t.matchId == match.id,
                        orElse: () => Tip.empty(widget.userId),
                      );

                      final tipId = tip.id.isNotEmpty
                          ? tip.id
                          : '${widget.userId}_${match.id}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
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
                                key: ValueKey(
                                  '${match.id}_${match.homeScore}_${match.guestScore}',
                                ),
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
        _UpcomingTipsHeader(
          isMobile: MediaQuery.of(context).size.width < 800,
          themeData: themeData,
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
        _UpcomingTipsHeader(
          isMobile: MediaQuery.of(context).size.width < 800,
          themeData: themeData,
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
        _UpcomingTipsHeader(
          isMobile: MediaQuery.of(context).size.width < 800,
          themeData: themeData,
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

class _UpcomingTipsHeader extends StatelessWidget {
  final bool isMobile;
  final ThemeData themeData;

  const _UpcomingTipsHeader({
    required this.isMobile,
    required this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = isMobile
        ? themeData.textTheme.headlineSmall?.copyWith(fontSize: 14)
        : themeData.textTheme.headlineSmall;

    return Row(
      children: [
        Text(
          'Aktuelle Spiele',
          style: titleStyle,
        ),
        const SizedBox(width: 4),
        const _UpcomingTipsLegendButton(),
        const Spacer(),
        TextButton(
          onPressed: () {
            Routemaster.of(context).push('/tips');
          },
          child: Text(
            'Alle Tipps anzeigen',
            style: TextStyle(
              color: themeData.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingTipsLegendButton extends StatelessWidget {
  const _UpcomingTipsLegendButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: 'Hinweis',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      icon: Icon(
        Icons.help_outline,
        size: 20,
        color: theme.colorScheme.onSurface.withOpacity(0.85),
      ),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UpcomingTipsLegendRow(
                    icon: Icons.delete_outline,
                    iconColor: Colors.white,
                    title: 'Tipp löschen',
                    description:
                        'Mit dem Papierkorb auf der Tipp-Karte kannst du deinen gespeicherten Tipp löschen.',
                  ),
                  SizedBox(height: 12),
                  _UpcomingTipsLegendRow(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: 'Joker',
                    description:
                        'Der Joker markiert einen Tipp, der doppelt gewertet wird..',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Verstanden',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UpcomingTipsLegendRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _UpcomingTipsLegendRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                ),
              ),
            ],
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

  bool _isTipLimitReached(TipControllerLoaded tipState, Tip tip) {
    if (tip.tipHome != null || tip.tipGuest != null) return false;

    final phase = MatchPhase.fromMatchDay(widget.matchDay);
    if (!phase.hasTipLimit) return false;

    if (phase == MatchPhase.groupStage) {
      final stats = tipState.matchDayStatistics[widget.matchDay];

      if (stats != null) {
        return stats.tippedGames >= phase.maxTips!;
      }
    }

    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;

      final bloc = context.read<TipFormBloc>();
      final controllerBloc = context.read<TipControllerBloc>();
      final tipState = controllerBloc.state;

      bloc.add(
        TipFormInitializedEvent(
          matchId: widget.matchId,
          userId: widget.userId,
          matchDay: widget.matchDay,
        ),
      );

      if (tipState is TipControllerLoaded) {
        final userTips = tipState.tips[widget.userId] ?? [];

        final tip = userTips.firstWhere(
          (t) => t.matchId == widget.matchId,
          orElse: () => Tip.empty(widget.userId),
        );

        bloc.add(
          TipFormExternalUpdateEvent(
            matchId: widget.matchId,
            matchDay: widget.matchDay,
            tipHome: tip.tipHome,
            tipGuest: tip.tipGuest,
            joker: tip.joker,
            isTipLimitReached: _isTipLimitReached(tipState, tip),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TipControllerBloc, TipControllerState>(
      listenWhen: (previous, current) {
        if (previous is TipControllerLoaded && current is TipControllerLoaded) {
          return previous.tips != current.tips ||
              previous.matchDayStatistics != current.matchDayStatistics;
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

          formBloc.add(
            TipFormExternalUpdateEvent(
              matchId: widget.matchId,
              matchDay: widget.matchDay,
              tipHome: tip.tipHome,
              tipGuest: tip.tipGuest,
              joker: tip.joker,
              isTipLimitReached: _isTipLimitReached(tipState, tip),
            ),
          );
        }
      },
      child: widget.child,
    );
  }
}
