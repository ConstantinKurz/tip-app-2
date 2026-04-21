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
  State<AdminUserTipDetailsPage> createState() => _AdminUserTipDetailsPageState();
}

class _AdminUserTipDetailsPageState extends State<AdminUserTipDetailsPage> {
  List<CustomMatch> _filteredMatches = [];
  int _buildCount = 0; // ✅ Build Counter für Debugging

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    print('🏗️  [AdminUserTipDetailsPage] BUILD #$_buildCount for user: ${widget.selectedUserId}');
    
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const contentMaxWidth = 700.0;
    final horizontalMargin = (screenWidth > contentMaxWidth)
        ? (screenWidth - contentMaxWidth) / 2
        : 16.0;

    return Scaffold(
      body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        buildWhen: (previous, current) {
          final shouldBuild = previous.runtimeType != current.runtimeType;
          print('   [AuthControllerBloc] buildWhen: $shouldBuild (${previous.runtimeType} -> ${current.runtimeType})');
          return shouldBuild;
        },
        builder: (context, authState) {
          return BlocBuilder<TipControllerBloc, TipControllerState>(
            buildWhen: (previous, current) {
              if (previous.runtimeType != current.runtimeType) {
                print('   [TipControllerBloc] buildWhen: TRUE (type change: ${previous.runtimeType} -> ${current.runtimeType})');
                return true;
              }
              
              if (previous is TipControllerLoaded && current is TipControllerLoaded) {
                final prevUserTips = previous.tips[widget.selectedUserId] ?? [];
                final currUserTips = current.tips[widget.selectedUserId] ?? [];
                
                if (prevUserTips.length != currUserTips.length) {
                  print('   [TipControllerBloc] buildWhen: TRUE (tip count changed: ${prevUserTips.length} -> ${currUserTips.length})');
                  return true;
                }
                
                for (int i = 0; i < prevUserTips.length; i++) {
                  if (prevUserTips[i] != currUserTips[i]) {
                    print('   [TipControllerBloc] buildWhen: TRUE (tip changed at index $i)');
                    return true;
                  }
                }
                
                print('   [TipControllerBloc] buildWhen: FALSE (no relevant changes)');
                return false;
              }
              
              return true;
            },
            builder: (context, tipState) {
              return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
                buildWhen: (previous, current) {
                  if (previous.runtimeType != current.runtimeType) {
                    print('   [MatchesControllerBloc] buildWhen: TRUE (type change)');
                    return true;
                  }
                  
                  if (previous is MatchesControllerLoaded && current is MatchesControllerLoaded) {
                    if (previous.matches.length != current.matches.length) {
                      print('   [MatchesControllerBloc] buildWhen: TRUE (match count changed)');
                      return true;
                    }
                    
                    for (int i = 0; i < previous.matches.length; i++) {
                      if (previous.matches[i] != current.matches[i]) {
                        print('   [MatchesControllerBloc] buildWhen: TRUE (match changed at index $i)');
                        return true;
                      }
                    }
                    
                    print('   [MatchesControllerBloc] buildWhen: FALSE (no changes)');
                    return false;
                  }
                  
                  return true;
                },
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
                            child: Text("Match Failure: ${matchState.matchFailure}"),
                          ),
                        );
                      }
                      if (teamState is TeamsControllerFailureState) {
                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: Text("Team Failure: ${teamState.teamFailure}"),
                          ),
                        );
                      }
                      if (authState is AuthControllerFailure) {
                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: Text("Auth Failure: ${authState.authFailure}"),
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
                        final filteredMatches = _filteredMatches.isNotEmpty ||
                                matches.isEmpty
                            ? _filteredMatches
                            : matches;

                        final selectedUser = authState.users.firstWhere(
                          (u) => u.id == widget.selectedUserId,
                          orElse: () => AppUser.empty(),
                        );

                        return Scaffold(
                          body: Stack(
                            children: [
                              PageTemplate(
                                isAuthenticated: widget.isAuthenticated,
                                child: Column(
                                  children: [
                                    // Header Text
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                          top: 60, bottom: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Tipps von ${selectedUser.name}",
                                            style: themeData.textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Rang: #${selectedUser.rank} • Punkte: ${selectedUser.score} • Joker: ${selectedUser.jokerSum}",
                                            style: themeData.textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Suchfeld
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
                                    // Tipps Liste
                                    Expanded(
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: contentMaxWidth),
                                          child: filteredMatches.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                    'Keine Matches gefunden',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )
                                              : ScrollablePositionedList
                                                  .separated(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 16.0,
                                                    horizontal: 16.0,
                                                  ),
                                                  itemCount:
                                                      filteredMatches.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(
                                                          height: 24),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final match =
                                                        filteredMatches[index];
                                                    final tip = userTips
                                                        .firstWhere(
                                                          (t) =>
                                                              t.matchId ==
                                                              match.id,
                                                          orElse: () => Tip
                                                              .empty(widget
                                                                  .selectedUserId)
                                                              .copyWith(
                                                                  matchId:
                                                                      match.id),
                                                        );
                                                    final homeTeam = teams
                                                        .firstWhere(
                                                          (t) =>
                                                              t.id ==
                                                              match.homeTeamId,
                                                          orElse: () =>
                                                              Team.empty(),
                                                        );
                                                    final guestTeam = teams
                                                        .firstWhere(
                                                          (t) =>
                                                              t.id ==
                                                              match.guestTeamId,
                                                          orElse: () =>
                                                              Team.empty(),
                                                        );

                                                    return BlocProvider<
                                                        TipFormBloc>(
                                                      create: (_) =>
                                                          sl<TipFormBloc>(),
                                                      child:
                                                          _AdminTipCardInitializer(
                                                        matchId: match.id,
                                                        userId: widget
                                                            .selectedUserId,
                                                        matchDay:
                                                            match.matchDay,
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
                                    icon: const Icon(Icons.close,
                                        size: 28, color: Colors.white),
                                    onPressed: () {
                                      Routemaster.of(context)
                                          .replace('/admin');
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
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

// ✅ Wrapper Widget um TipUpdateStatisticsEvent nur EINMAL zu triggern
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
  bool _statsRequested = false; // ✅ Verhindert mehrfache Stats-Requests
  int _buildCount = 0; // ✅ Build Counter

  /// Prüft ob das Tipp-Limit für die Gruppenphase erreicht ist
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
  void initState() {
    super.initState();
    print('🎬 [_AdminTipCardInitializer] INIT for match: ${widget.matchId}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 [_AdminTipCardInitializer] didChangeDependencies for match: ${widget.matchId}');
    print('   _initialized: $_initialized, _statsRequested: $_statsRequested');
    
    if (!_initialized) {
      _initialized = true;
      print('   ✅ INITIALIZING match: ${widget.matchId}, matchDay: ${widget.matchDay}');

      final formBloc = context.read<TipFormBloc>();
      final controllerBloc = context.read<TipControllerBloc>();
      final tipState = controllerBloc.state;

      formBloc.add(
        TipFormInitializedEvent(
          userId: widget.userId,
          matchId: widget.matchId,
          matchDay: widget.matchDay,
        ),
      );

      // Stats nur laden wenn nicht bereits vorhanden
      if (tipState is TipControllerLoaded) {
        final hasStats = tipState.matchDayStatistics.containsKey(widget.matchDay);
        print('   hasStats for matchDay ${widget.matchDay}: $hasStats');
        
        if (!hasStats && !_statsRequested) {
          _statsRequested = true;
          print('   📊 REQUESTING STATS for matchDay ${widget.matchDay}');
          
          controllerBloc.add(
            TipUpdateStatisticsEvent(
              userId: widget.userId,
              matchDay: widget.matchDay,
            ),
          );
        } else {
          print('   ⏭️  SKIPPING stats request (hasStats: $hasStats, already requested: $_statsRequested)');
        }

        // Tip-Daten direkt übergeben
        formBloc.add(TipFormExternalUpdateEvent(
          matchId: widget.matchId,
          matchDay: widget.matchDay,
          tipHome: widget.tip.tipHome,
          tipGuest: widget.tip.tipGuest,
          joker: widget.tip.joker,
          isTipLimitReached: _isTipLimitReached(tipState, widget.tip),
        ));
      } else {
        if (!_statsRequested) {
          _statsRequested = true;
          print('   📊 REQUESTING STATS (TipControllerNotLoaded) for matchDay ${widget.matchDay}');
          controllerBloc.add(
            TipUpdateStatisticsEvent(
              userId: widget.userId,
              matchDay: widget.matchDay,
            ),
          );
        }
      }
    } else {
      print('   ⏭️  SKIPPED: Already initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    print('🏗️  [_AdminTipCardInitializer] BUILD #$_buildCount for match: ${widget.matchId}');
    
    return BlocListener<TipControllerBloc, TipControllerState>(
      listenWhen: (previous, current) {
        if (previous.runtimeType != current.runtimeType) return true;
        
        if (previous is TipControllerLoaded && current is TipControllerLoaded) {
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
          
          final shouldListen = prevTip != currTip ||
              previous.matchDayStatistics != current.matchDayStatistics;
          print('   [_AdminTipCardInitializer] listenWhen for ${widget.matchId}: $shouldListen');
          return shouldListen;
        }
        
        return false;
      },
      listener: (context, tipState) {
        print('👂 [_AdminTipCardInitializer] LISTENER triggered for match: ${widget.matchId}');
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
            isTipLimitReached: _isTipLimitReached(tipState, tip),
          ));
        }
      },
      child: TipCard(
        key: ValueKey(widget.matchId),
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
