import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/match_phase.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/core/widgets/match_search_field.dart';
import 'package:flutter_web/presentation/tip_card/tip_card.dart';
import 'package:routemaster/routemaster.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TipPage extends StatefulWidget {
  final bool isAuthenticated;
  final int? initialScrollIndex;
  final String? initialFilter;

  const TipPage({
    Key? key,
    required this.isAuthenticated,
    this.initialScrollIndex,
    this.initialFilter,
  }) : super(key: key);

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  List<CustomMatch> _filteredMatches = [];
  String? _currentFilter;
  final Map<String, TipFormBloc> _tipFormBlocs = {};
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Set<int> _loadedMatchDays = {};
  String? _lastUserId;
  bool _initialStatsLoaded = false;
  Key? _listKey;

  @override
  void initState() {
    super.initState();

    if (widget.initialScrollIndex != null) {
      _listKey = ValueKey('list_${widget.initialScrollIndex}');
    }

    _currentFilter = widget.initialFilter;
  }

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

  void _checkAndResetForUser(String userId) {
    if (_lastUserId != userId) {
      _loadedMatchDays.clear();
      _initialStatsLoaded = false;
      _lastUserId = userId;

      debugPrint(
        '🔄 [TipPage] User changed: $_lastUserId → $userId, resetting stats',
      );
    }
  }

  int _findCurrentOrNextMatchIndex(List<CustomMatch> matches) {
    final now = DateTime.now();
    const matchDuration = 120;

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final matchEndTime = match.matchDate.add(
        const Duration(minutes: matchDuration),
      );

      if (matchEndTime.isAfter(now)) {
        return i;
      }
    }

    return matches.isEmpty ? 0 : matches.length - 1;
  }

  void _loadMissingStatistics(
    List<CustomMatch> filteredMatches,
    String userId,
    BuildContext context,
  ) {
    if (filteredMatches.isEmpty) return;

    final newMatchDays = filteredMatches.map((m) => m.matchDay).toSet();
    final missingMatchDays = newMatchDays.difference(_loadedMatchDays);

    if (missingMatchDays.isNotEmpty) {
      try {
        final tipsBloc = context.read<TipControllerBloc>();

        for (final matchDay in missingMatchDays) {
          tipsBloc.add(
            TipUpdateStatisticsEvent(
              userId: userId,
              matchDay: matchDay,
            ),
          );
        }

        _loadedMatchDays.addAll(missingMatchDays);

        debugPrint(
          '📊 [TipPage] Statistiken geladen für Spieltage: $missingMatchDays',
        );
      } catch (e) {
        debugPrint('❌ [TipPage] Fehler beim Laden der Statistiken: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const contentMaxWidth = 700.0;

    final horizontalMargin = screenWidth > contentMaxWidth
        ? (screenWidth - contentMaxWidth) / 2
        : 16.0;

    final isMobile = screenWidth < 800;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PageTemplate(
      isAuthenticated: widget.isAuthenticated,
      floatingActionButton: isMobile && isKeyboardVisible
          ? null
          : Padding(
              padding: EdgeInsets.only(
                right: horizontalMargin,
                bottom: 16,
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Routemaster.of(context).push('/home');
                },
                icon: const Icon(Icons.home),
                label: const Text(
                  'Home',
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.onPrimary,
                  foregroundColor: themeData.colorScheme.primary,
                  textStyle: themeData.textTheme.bodyLarge,
                  minimumSize: const Size(140, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        builder: (context, authState) {
          return BlocBuilder<TipControllerBloc, TipControllerState>(
            builder: (context, tipState) {
              return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
                builder: (context, matchState) {
                  return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
                    builder: (context, teamState) {
                      if (authState is AuthControllerLoaded &&
                          tipState is TipControllerLoaded &&
                          matchState is MatchesControllerLoaded &&
                          teamState is TeamsControllerLoaded) {
                        final userId = authState.signedInUser?.id ?? '';
                        final matches = matchState.matches;
                        final teams = teamState.teams;

                        _checkAndResetForUser(userId);

                        if (matches.isEmpty || teams.isEmpty) {
                          return Center(
                            child: Text(
                              'Keine Matches verfügbar',
                              style: themeData.textTheme.bodyLarge,
                            ),
                          );
                        }

                        final displayedMatches = _filteredMatches.isEmpty
                            ? matches
                            : _filteredMatches;

                        if (!_initialStatsLoaded &&
                            displayedMatches.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadMissingStatistics(
                              displayedMatches,
                              userId,
                              context,
                            );
                          });

                          _initialStatsLoaded = true;
                        }

                        if (displayedMatches.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Keine Matches gefunden',
                                  style: themeData.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _filteredMatches = [];
                                    });
                                  },
                                  child: const Text('Filter zurücksetzen'),
                                ),
                              ],
                            ),
                          );
                        }

                        final int targetIndex;
                        if (widget.initialScrollIndex != null) {
                          targetIndex = widget.initialScrollIndex!;
                        } else {
                          targetIndex =
                              _findCurrentOrNextMatchIndex(displayedMatches);
                        }

                        final safeIndex = targetIndex.clamp(
                          0,
                          displayedMatches.length - 1,
                        );

                        return Stack(
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalMargin,
                                  ),
                                  child: Row(
                                    children: [
                                      const _TipCardLegendButton(),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: MatchSearchField(
                                          matches: matches,
                                          teams: teams,
                                          hintText:
                                              'Nach Teams, Spielphase oder Matchtag suchen...',
                                          initialFilter: _currentFilter,
                                          onFilterChanged: (filter) {
                                            _currentFilter =
                                                filter?.isNotEmpty == true
                                                    ? filter
                                                    : null;
                                          },
                                          onFilteredMatchesChanged: (filtered) {
                                            setState(() {
                                              _filteredMatches = filtered;
                                            });

                                            _loadMissingStatistics(
                                              filtered,
                                              userId,
                                              context,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: contentMaxWidth,
                                      child: ScrollablePositionedList.separated(
                                        key: _listKey,
                                        initialScrollIndex: safeIndex,
                                        itemScrollController:
                                            _itemScrollController,
                                        itemPositionsListener:
                                            _itemPositionsListener,
                                        padding: const EdgeInsets.only(
                                          top: 16.0,
                                          bottom: 100.0,
                                        ),
                                        itemCount: displayedMatches.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 24),
                                        itemBuilder: (context, index) {
                                          final match = displayedMatches[index];

                                          final homeTeam = teams.firstWhere(
                                            (t) => t.id == match.homeTeamId,
                                            orElse: () => Team.empty(),
                                          );

                                          final guestTeam = teams.firstWhere(
                                            (t) => t.id == match.guestTeamId,
                                            orElse: () => Team.empty(),
                                          );

                                          final tip =
                                              (tipState.tips[userId] ?? [])
                                                  .firstWhere(
                                            (t) => t.matchId == match.id,
                                            orElse: () => Tip.empty(userId),
                                          );

                                          final bloc =
                                              _getTipFormBloc(match.id);

                                          return InkWell(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: () {
                                              final tipId = tip.id.isNotEmpty
                                                  ? tip.id
                                                  : '${userId}_${match.id}';

                                              final filterParam = _currentFilter !=
                                                      null
                                                  ? '&filter=${Uri.encodeComponent(_currentFilter!)}'
                                                  : '';

                                              Routemaster.of(context).push(
                                                '/tips-detail/$tipId?returnIndex=$index$filterParam',
                                              );
                                            },
                                            child:
                                                BlocProvider<TipFormBloc>.value(
                                              value: bloc,
                                              child: _TipCardInitializer(
                                                key: ValueKey(match.id),
                                                matchId: match.id,
                                                userId: userId,
                                                matchDay: match.matchDay,
                                                match: match,
                                                homeTeam: homeTeam,
                                                guestTeam: guestTeam,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Center(
                        child: CircularProgressIndicator(
                          color: themeData.colorScheme.onPrimaryContainer,
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
    );
  }
}

class _TipCardLegendButton extends StatelessWidget {
  const _TipCardLegendButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      tooltip: 'Hinweis',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      icon: Icon(
        Icons.help_outline,
        size: 24,
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
                  _TipCardLegendRow(
                    icon: Icons.delete_outline,
                    iconColor: Colors.white,
                    title: 'Tipp löschen',
                    description:
                        'Mit dem Papierkorb auf der Tipp-Karte kannst du deinen gespeicherten Tipp löschen.',
                  ),
                  SizedBox(height: 12),
                  _TipCardLegendRow(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: 'Joker',
                    description:
                        'Der Joker markiert einen Tipp, der doppelt gewertet wird.',
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

class _TipCardLegendRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _TipCardLegendRow({
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
  final CustomMatch match;
  final Team homeTeam;
  final Team guestTeam;

  const _TipCardInitializer({
    Key? key,
    required this.matchId,
    required this.userId,
    required this.matchDay,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
  }) : super(key: key);

  @override
  State<_TipCardInitializer> createState() => _TipCardInitializerState();
}

class _TipCardInitializerState extends State<_TipCardInitializer> {
  bool _initialized = false;
  String? _initializedForMatchId;

  @override
  void didUpdateWidget(covariant _TipCardInitializer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.matchId != widget.matchId) {
      _initialized = false;
      _initializedForMatchId = null;
    }
  }

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

    if (!_initialized || _initializedForMatchId != widget.matchId) {
      _initialized = true;
      _initializedForMatchId = widget.matchId;

      final formBloc = context.read<TipFormBloc>();
      final controllerBloc = context.read<TipControllerBloc>();
      final tipState = controllerBloc.state;

      if (formBloc.state.matchId != widget.matchId) {
        formBloc.add(
          TipFormInitializedEvent(
            userId: widget.userId,
            matchDay: widget.matchDay,
            matchId: widget.matchId,
          ),
        );
      }

      if (tipState is TipControllerLoaded) {
        final hasStats =
            tipState.matchDayStatistics.containsKey(widget.matchDay);

        if (!hasStats) {
          controllerBloc.add(
            TipUpdateStatisticsEvent(
              userId: widget.userId,
              matchDay: widget.matchDay,
            ),
          );
        }

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
      } else {
        controllerBloc.add(
          TipUpdateStatisticsEvent(
            userId: widget.userId,
            matchDay: widget.matchDay,
          ),
        );

        formBloc.add(
          TipFormExternalUpdateEvent(
            matchId: widget.matchId,
            matchDay: widget.matchDay,
            tipHome: null,
            tipGuest: null,
            joker: false,
            isTipLimitReached: false,
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
      child: BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
        buildWhen: (previous, current) {
          if (previous is MatchesControllerLoaded &&
              current is MatchesControllerLoaded) {
            final prevMatch = previous.matches.firstWhere(
              (m) => m.id == widget.matchId,
              orElse: () => widget.match,
            );

            final currMatch = current.matches.firstWhere(
              (m) => m.id == widget.matchId,
              orElse: () => widget.match,
            );

            return prevMatch.homeScore != currMatch.homeScore ||
                prevMatch.guestScore != currMatch.guestScore;
          }

          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, matchState) {
          CustomMatch currentMatch = widget.match;

          if (matchState is MatchesControllerLoaded) {
            currentMatch = matchState.matches.firstWhere(
              (m) => m.id == widget.matchId,
              orElse: () => widget.match,
            );
          }

          return BlocBuilder<TipControllerBloc, TipControllerState>(
            buildWhen: (previous, current) {
              if (previous is TipControllerLoaded &&
                  current is TipControllerLoaded) {
                final prevUserTips = previous.tips[widget.userId] ?? [];
                final currUserTips = current.tips[widget.userId] ?? [];

                final prevTip = prevUserTips.firstWhere(
                  (t) => t.matchId == widget.matchId,
                  orElse: () => Tip.empty(widget.userId),
                );

                final currTip = currUserTips.firstWhere(
                  (t) => t.matchId == widget.matchId,
                  orElse: () => Tip.empty(widget.userId),
                );

                return prevTip.points != currTip.points ||
                    prevTip.tipHome != currTip.tipHome ||
                    prevTip.tipGuest != currTip.tipGuest ||
                    prevTip.joker != currTip.joker;
              }

              return previous.runtimeType != current.runtimeType;
            },
            builder: (context, tipState) {
              Tip currentTip = Tip.empty(widget.userId);

              if (tipState is TipControllerLoaded) {
                final userTips = tipState.tips[widget.userId] ?? [];

                currentTip = userTips.firstWhere(
                  (t) => t.matchId == widget.matchId,
                  orElse: () => Tip.empty(widget.userId),
                );
              }

              return TipCard(
                key: ValueKey(
                  '${widget.matchId}_${currentTip.points}_${currentMatch.homeScore}_${currentMatch.guestScore}',
                ),
                userId: widget.userId,
                match: currentMatch,
                homeTeam: widget.homeTeam,
                guestTeam: widget.guestTeam,
                tip: currentTip,
              );
            },
          );
        },
      ),
    );
  }
}
