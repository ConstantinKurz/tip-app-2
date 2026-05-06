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
import 'package:flutter_web/presentation/tip_card/tip_card.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_details_community_tip_list.dart';
import 'package:routemaster/routemaster.dart';

class TipDetailsPage extends StatefulWidget {
  final bool isAuthenticated;
  final String tipId;
  final int? returnIndex;
  final String? from;

  const TipDetailsPage({
    Key? key,
    required this.isAuthenticated,
    required this.tipId,
    this.returnIndex,
    this.from,
  }) : super(key: key);

  @override
  State<TipDetailsPage> createState() => _TipDetailsPageState();
}

class _TipDetailsPageState extends State<TipDetailsPage> {
  TipFormBloc? _tipFormBloc;
  bool _statsLoaded = false;
  bool _matchTipsLoaded = false; // ✅ Tracking ob Match-Tips geladen wurden
  String? _lastMatchId; // ✅ Track matchId to reset on change

  @override
  void dispose() {
    _tipFormBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeData = RouteData.of(context);
    final from = routeData.queryParameters['from'];
    final returnIndexString = routeData.queryParameters['returnIndex'];

    return Scaffold(
      body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
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
                        final tips = tipState.tips;
                        final userTips = tips[userId] ?? [];
                        final tip = userTips.firstWhere(
                          (t) => t.id == widget.tipId,
                          orElse: () => Tip.empty(userId),
                        );
                        
                        // If tip does not exist matchId within tip is still empty. Get it from tipId.
                        final splitIndex = widget.tipId.indexOf('_');
                        final matchId = widget.tipId.substring(splitIndex + 1);
                        
                        // ✅ Reset flags wenn matchId wechselt
                        if (_lastMatchId != matchId) {
                          _lastMatchId = matchId;
                          _statsLoaded = false;
                          _matchTipsLoaded = false;
                        }
                        
                        final match = matchState.matches.firstWhere(
                          (m) => m.id == matchId,
                          orElse: () => CustomMatch.empty(),
                        );
                        final homeTeam = teamState.teams.firstWhere(
                          (t) => t.id == match.homeTeamId,
                          orElse: () => Team.empty(),
                        );
                        final guestTeam = teamState.teams.firstWhere(
                          (t) => t.id == match.guestTeamId,
                          orElse: () => Team.empty(),
                        );

                        if (!_statsLoaded && match.id.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<TipControllerBloc>().add(
                                  TipUpdateStatisticsEvent(
                                    userId: userId,
                                    matchDay: match.matchDay,
                                  ),
                                );
                          });
                          _statsLoaded = true;
                        }

                        // ✅ NEU: Lade alle Tips für dieses Match (für CommunityTipList)
                        if (!_matchTipsLoaded && match.id.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            context.read<TipControllerBloc>().add(
                                  TipLoadForMatchEvent(matchId: match.id),
                                );
                          });
                          _matchTipsLoaded = true;
                        }

                        // Create TipFormBloc once for this match
                        _tipFormBloc ??= sl<TipFormBloc>();

                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 700),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () {
                                                if (from == 'tip' &&
                                                    returnIndexString != null) {
                                                  Routemaster.of(context).replace(
                                                      '/tips?scrollTo=$returnIndexString');
                                                } else {
                                                  Routemaster.of(context).replace('/home');
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        BlocProvider<TipFormBloc>.value(
                                          value: _tipFormBloc!,
                                          child: _TipCardInitializer(
                                            matchId: match.id,
                                            userId: userId,
                                            matchDay: match.matchDay,
                                            child: TipCard(
                                              userId: userId,
                                              tip: tip,
                                              homeTeam: homeTeam,
                                              guestTeam: guestTeam,
                                              match: match,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          height: 500,
                                          child: CommunityTipList(
                                            users: authState.users,
                                            allTips: tipState.tips,
                                            match: match,
                                            currentUserId: userId,
                                            teams: teamState.teams,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Show loading indicator while data is loading
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;

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
          isTipLimitReached: _isTipLimitReached(tipState, tip),
        ));
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
      child: widget.child,
    );
  }
}
