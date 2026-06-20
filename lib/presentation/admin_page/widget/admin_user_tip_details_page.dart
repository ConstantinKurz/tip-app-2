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
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/core/widgets/match_search_field.dart';
import 'package:flutter_web/presentation/tip_card/tip_card.dart';
import 'package:routemaster/routemaster.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class AdminUserTipDetailsPage extends StatefulWidget {
  final bool isAuthenticated;
  final String selectedUserId;

  const AdminUserTipDetailsPage({
    Key? key,
    required this.isAuthenticated,
    required this.selectedUserId,
  }) : super(key: key);

  @override
  State<AdminUserTipDetailsPage> createState() =>
      _AdminUserTipDetailsPageState();
}

class _AdminUserTipDetailsPageState extends State<AdminUserTipDetailsPage> {
  List<CustomMatch> _filteredMatches = [];

  /// Merkt sich, für welche MatchDays die Statistik für den ausgewählten User
  /// bereits neu geladen wurde.
  ///
  /// Wichtig:
  /// tipState.matchDayStatistics ist offenbar nur nach matchDay keyed.
  /// Deshalb darf man NICHT einfach containsKey(matchDay) prüfen,
  /// weil dort noch die Statistik des Admins liegen kann.
  final Set<int> _requestedStatsMatchDays = {};

  @override
  void didUpdateWidget(covariant AdminUserTipDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedUserId != widget.selectedUserId) {
      _filteredMatches = [];
      _requestedStatsMatchDays.clear();
    }
  }

  void _requestSelectedUserStatisticsOnce({
    required BuildContext context,
    required List<CustomMatch> matches,
  }) {
    final matchDays = matches.map((match) => match.matchDay).toSet();

    for (final matchDay in matchDays) {
      if (_requestedStatsMatchDays.contains(matchDay)) {
        continue;
      }

      _requestedStatsMatchDays.add(matchDay);

      context.read<TipControllerBloc>().add(
            TipUpdateStatisticsEvent(
              userId: widget.selectedUserId,
              matchDay: matchDay,
              forceRefresh: true,
            ),
          );
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

    return Scaffold(
      body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        builder: (context, authState) {
          return BlocBuilder<TipControllerBloc, TipControllerState>(
            builder: (context, tipState) {
              return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
                builder: (context, matchState) {
                  return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
                    builder: (context, teamState) {
                      if (tipState is TipControllerFailure) {
                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: Text("Tip Failure: ${tipState.tipFailure}"),
                          ),
                        );
                      }

                      if (matchState is MatchesControllerFailure) {
                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: Text(
                              "Match Failure: ${matchState.matchFailure}",
                            ),
                          ),
                        );
                      }

                      if (teamState is TeamsControllerFailureState) {
                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child:
                                Text("Team Failure: ${teamState.teamFailure}"),
                          ),
                        );
                      }

                      if (authState is AuthControllerFailure) {
                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child:
                                Text("Auth Failure: ${authState.authFailure}"),
                          ),
                        );
                      }

                      if (tipState is TipControllerLoaded &&
                          matchState is MatchesControllerLoaded &&
                          teamState is TeamsControllerLoaded &&
                          authState is AuthControllerLoaded) {
                        final teams = teamState.teams;
                        final matches = matchState.matches;
                        final tips = tipState.tips;

                        final userTips = tips[widget.selectedUserId] ?? [];

                        final filteredMatches =
                            _filteredMatches.isNotEmpty || matches.isEmpty
                                ? _filteredMatches
                                : matches;

                        final selectedUser = authState.users.firstWhere(
                          (u) => u.id == widget.selectedUserId,
                          orElse: () => AppUser.empty(),
                        );

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;

                          _requestSelectedUserStatisticsOnce(
                            context: context,
                            matches: matches,
                          );
                        });

                        return Stack(
                          children: [
                            PageTemplate(
                              isAuthenticated: widget.isAuthenticated,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                      top: 60,
                                      bottom: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Tipps von ${selectedUser.name}",
                                          style: themeData
                                              .textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Rang: #${selectedUser.rank} • Punkte: ${selectedUser.score} • Joker: ${selectedUser.jokerSum}",
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MatchSearchField(
                                    matches: matches,
                                    teams: teams,
                                    hintText:
                                        "Nach Teams, Spielphase oder Matchtag suchen...",
                                    showHelpDialog: false,
                                    onFilteredMatchesChanged: (filtered) {
                                      setState(() {
                                        _filteredMatches = filtered;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: contentMaxWidth,
                                        ),
                                        child: filteredMatches.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'Keine Matches gefunden',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                            : ScrollablePositionedList
                                                .separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 16.0,
                                                  horizontal: 16.0,
                                                ),
                                                itemCount:
                                                    filteredMatches.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 24),
                                                itemBuilder: (context, index) {
                                                  final match =
                                                      filteredMatches[index];

                                                  final tip =
                                                      userTips.firstWhere(
                                                    (t) =>
                                                        t.matchId == match.id,
                                                    orElse: () => Tip.empty(
                                                      widget.selectedUserId,
                                                    ).copyWith(
                                                      matchId: match.id,
                                                    ),
                                                  );

                                                  final homeTeam =
                                                      teams.firstWhere(
                                                    (t) =>
                                                        t.id ==
                                                        match.homeTeamId,
                                                    orElse: () => Team.empty(),
                                                  );

                                                  final guestTeam =
                                                      teams.firstWhere(
                                                    (t) =>
                                                        t.id ==
                                                        match.guestTeamId,
                                                    orElse: () => Team.empty(),
                                                  );

                                                  return BlocProvider<
                                                      TipFormBloc>(
                                                    key: ValueKey(
                                                      '${widget.selectedUserId}_${match.id}_provider',
                                                    ),
                                                    create: (_) =>
                                                        sl<TipFormBloc>(),
                                                    child:
                                                        _AdminTipCardInitializer(
                                                      key: ValueKey(
                                                        '${widget.selectedUserId}_${match.id}_initializer',
                                                      ),
                                                      matchId: match.id,
                                                      userId:
                                                          widget.selectedUserId,
                                                      matchDay: match.matchDay,
                                                      match: match,
                                                      homeTeam: homeTeam,
                                                      guestTeam: guestTeam,
                                                      tip: tip,
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: horizontalMargin,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Routemaster.of(context).replace('/admin');
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return PageTemplate(
                        isAuthenticated: widget.isAuthenticated,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: themeData.colorScheme.onPrimaryContainer,
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
      ),
    );
  }
}

class _AdminTipCardInitializer extends StatefulWidget {
  final String matchId;
  final String userId;
  final int matchDay;
  final CustomMatch match;
  final Team homeTeam;
  final Team guestTeam;
  final Tip tip;

  const _AdminTipCardInitializer({
    Key? key,
    required this.matchId,
    required this.userId,
    required this.matchDay,
    required this.match,
    required this.homeTeam,
    required this.guestTeam,
    required this.tip,
  }) : super(key: key);

  @override
  State<_AdminTipCardInitializer> createState() =>
      _AdminTipCardInitializerState();
}

class _AdminTipCardInitializerState extends State<_AdminTipCardInitializer> {
  bool _initialized = false;

  bool _isTipLimitReached(TipControllerLoaded tipState, Tip tip) {
    if (tip.tipHome != null || tip.tipGuest != null) {
      return false;
    }

    final phase = MatchPhase.fromMatchDay(widget.matchDay);

    if (!phase.hasTipLimit) {
      return false;
    }

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

    if (_initialized) {
      return;
    }

    _initialized = true;

    final formBloc = context.read<TipFormBloc>();
    final tipState = context.read<TipControllerBloc>().state;

    formBloc.add(
      TipFormInitializedEvent(
        userId: widget.userId,
        matchId: widget.matchId,
        matchDay: widget.matchDay,
      ),
    );

    if (tipState is TipControllerLoaded) {
      formBloc.add(
        TipFormExternalUpdateEvent(
          matchId: widget.matchId,
          matchDay: widget.matchDay,
          tipHome: widget.tip.tipHome,
          tipGuest: widget.tip.tipGuest,
          joker: widget.tip.joker,
          isTipLimitReached: _isTipLimitReached(tipState, widget.tip),
        ),
      );
    } else {
      formBloc.add(
        TipFormExternalUpdateEvent(
          matchId: widget.matchId,
          matchDay: widget.matchDay,
          tipHome: widget.tip.tipHome,
          tipGuest: widget.tip.tipGuest,
          joker: widget.tip.joker,
          isTipLimitReached: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TipControllerBloc, TipControllerState>(
      listenWhen: (previous, current) {
        if (previous.runtimeType != current.runtimeType) {
          return true;
        }

        if (previous is TipControllerLoaded && current is TipControllerLoaded) {
          final previousUserTips = previous.tips[widget.userId] ?? [];
          final currentUserTips = current.tips[widget.userId] ?? [];

          final previousTip = previousUserTips.firstWhere(
            (t) => t.matchId == widget.matchId,
            orElse: () => Tip.empty(widget.userId),
          );

          final currentTip = currentUserTips.firstWhere(
            (t) => t.matchId == widget.matchId,
            orElse: () => Tip.empty(widget.userId),
          );

          return previousTip != currentTip ||
              previous.matchDayStatistics != current.matchDayStatistics;
        }

        return false;
      },
      listener: (context, tipState) {
        if (tipState is! TipControllerLoaded) {
          return;
        }

        final formBloc = context.read<TipFormBloc>();

        final userTips = tipState.tips[widget.userId] ?? [];

        final tip = userTips.firstWhere(
          (t) => t.matchId == widget.matchId,
          orElse: () => Tip.empty(widget.userId).copyWith(
            matchId: widget.matchId,
          ),
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
      },
      child: TipCard(
        key: ValueKey('${widget.userId}_${widget.matchId}'),
        userId: widget.userId,
        match: widget.match,
        homeTeam: widget.homeTeam,
        guestTeam: widget.guestTeam,
        tip: widget.tip,
        isAdmin: true,
      ),
    );
  }
}
