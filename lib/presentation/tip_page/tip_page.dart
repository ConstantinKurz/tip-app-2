import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
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

  const TipPage({
    Key? key,
    required this.isAuthenticated,
    this.initialScrollIndex,
  }) : super(key: key);

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  List<CustomMatch> _filteredMatches = [];
  final Map<String, TipFormBloc> _tipFormBlocs = {};
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _hasInitialScrolled = false;

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

  /// ✅ Findet Index des nächsten Spiels oder aktuell laufenden Spiels
  int _findCurrentOrNextMatchIndex(List<CustomMatch> matches) {
    final now = DateTime.now();
    const matchDuration = 120; // Minuten

    // Finde erstes Spiel das noch läuft oder in der Zukunft liegt
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final matchEndTime = match.matchDate.add(const Duration(minutes: matchDuration));
      
      // Spiel läuft noch oder ist in der Zukunft
      if (matchEndTime.isAfter(now)) {
        return i;
      }
    }

    // Fallback: Springe zum letzten Spiel
    return matches.isEmpty ? 0 : matches.length - 1;
  }

  /// ✅ Scrollt zum initialen Index (nur einmal)
  void _scrollToInitialPosition(int targetIndex, int maxIndex) {
    if (_hasInitialScrolled) return;
    if (!_itemScrollController.isAttached) return;
    
    final safeIndex = targetIndex.clamp(0, maxIndex);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemScrollController.isAttached && mounted) {
        _itemScrollController.scrollTo(
          index: safeIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1, // 10% vom oberen Rand
        );
        setState(() {
          _hasInitialScrolled = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const contentMaxWidth = 700.0;
    final horizontalMargin = (screenWidth - contentMaxWidth).clamp(16.0, double.infinity) / 2;

    return PageTemplate(
      isAuthenticated: widget.isAuthenticated,
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

                        if (matches.isEmpty || teams.isEmpty) {
                          return Center(
                            child: Text(
                              'Keine Matches verfügbar',
                              style: themeData.textTheme.bodyLarge,
                            ),
                          );
                        }

                        // ✅ Nutze gefilterte oder alle Matches
                        final displayedMatches = _filteredMatches.isEmpty
                            ? matches
                            : _filteredMatches;

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
                                      _hasInitialScrolled = false; // Reset scroll bei neuem Filter
                                    });
                                  },
                                  child: const Text('Filter zurücksetzen'),
                                ),
                              ],
                            ),
                          );
                        }

                        // ✅ Bestimme initialen Scroll-Index
                        final int targetIndex;
                        if (widget.initialScrollIndex != null) {
                          // Von Detail-Page zurück
                          targetIndex = widget.initialScrollIndex!;
                        } else {
                          // Normaler Aufruf: Springe zum aktuellen/nächsten Spiel
                          targetIndex = _findCurrentOrNextMatchIndex(displayedMatches);
                        }

                        // ✅ Scroll nur einmal nach Build
                        _scrollToInitialPosition(targetIndex, displayedMatches.length - 1);

                        return Stack(
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                                  child: MatchSearchField(
                                    matches: matches,
                                    teams: teams,
                                    hintText: "Nach Teams, Spielphase oder Matchtag suchen...",
                                    onFilteredMatchesChanged: (filtered) {
                                      setState(() {
                                        _filteredMatches = filtered;
                                        _hasInitialScrolled = false; // Reset scroll bei neuem Filter
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: contentMaxWidth,
                                      child: ScrollablePositionedList.separated(
                                        itemScrollController: _itemScrollController,
                                        itemPositionsListener: _itemPositionsListener,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16.0,
                                          horizontal: 16.0,
                                        ),
                                        itemCount: displayedMatches.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 24),
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

                                          final tip = (tipState.tips[userId] ?? [])
                                              .firstWhere(
                                            (t) => t.matchId == match.id,
                                            orElse: () => Tip.empty(userId),
                                          );

                                          final bloc = _getTipFormBloc(match.id);

                                          return InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () {
                                              final tipId = tip.id.isNotEmpty
                                                  ? tip.id
                                                  : "${userId}_${match.id}";
                                              Routemaster.of(context).push(
                                                '/tips-detail/$tipId?from=tip&returnIndex=$index',
                                              );
                                            },
                                            child: BlocProvider<TipFormBloc>.value(
                                              value: bloc,
                                              child: _TipCardInitializer(
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
                            Positioned(
                              right: horizontalMargin,
                              bottom: 16,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Routemaster.of(context).push('/home');
                                },
                                icon: const Icon(Icons.home),
                                label: const Text('Home', overflow: TextOverflow.ellipsis),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeData.colorScheme.onPrimary,
                                  foregroundColor: themeData.colorScheme.primary,
                                  textStyle: themeData.textTheme.bodyLarge,
                                  minimumSize: const Size(140, 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final formBloc = context.read<TipFormBloc>();
      final controllerBloc = context.read<TipControllerBloc>();

      if (formBloc.state.matchId != widget.matchId) {
        formBloc.add(
          TipFormInitializedEvent(
            userId: widget.userId,
            matchDay: widget.matchDay,
            matchId: widget.matchId,
          ),
        );
      }

      controllerBloc.add(
        TipUpdateStatisticsEvent(
          userId: widget.userId,
          matchDay: widget.matchDay,
        ),
      );

      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipState = context.watch<TipControllerBloc>().state;
    
    Tip currentTip = Tip.empty(widget.userId);
    if (tipState is TipControllerLoaded) {
      final userTips = tipState.tips[widget.userId] ?? [];
      currentTip = userTips.firstWhere(
        (t) => t.matchId == widget.matchId,
        orElse: () => Tip.empty(widget.userId),
      );
    }

    return TipCard(
      key: ValueKey(widget.matchId),
      userId: widget.userId,
      match: widget.match,
      homeTeam: widget.homeTeam,
      guestTeam: widget.guestTeam,
      tip: currentTip,
    );
  }
}
