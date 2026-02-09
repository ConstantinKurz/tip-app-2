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
    return Scaffold(
      body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        builder: (context, authState) {
          return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
            builder: (context, matchState) {
              return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
                builder: (context, teamState) {
                  if (matchState is MatchesControllerFailure) {
                    return const Center(child: Text('Fehler beim Laden der Matches'));
                  }

                  if (matchState is! MatchesControllerLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (teamState is! TeamsControllerLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final matches = matchState.matches;
                  final teams = teamState.teams;
                  final userId = authState is AuthControllerLoaded
                      ? authState.signedInUser?.id ?? ''
                      : '';

                  return PageTemplate(
                    isAuthenticated: widget.isAuthenticated,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          children: [
                            // Suchfeld
                            MatchSearchField(
                              matches: matches,
                              teams: teams,
                              onFilteredMatchesChanged: (filtered) {
                                setState(() {
                                  _filteredMatches = filtered;
                                });
                              },
                            ),

                            // Matches Liste
                            Expanded(
                              child: _filteredMatches.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Keine Matches gefunden',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : ScrollablePositionedList.separated(
                                      itemCount: _filteredMatches.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 16),
                                      itemBuilder: (context, index) {
                                        final match = _filteredMatches[index];
                                        final homeTeam = teams.firstWhere(
                                          (t) => t.id == match.homeTeamId,
                                          orElse: () => Team.empty(),
                                        );
                                        final guestTeam = teams.firstWhere(
                                          (t) => t.id == match.guestTeamId,
                                          orElse: () => Team.empty(),
                                        );
                                        // ✅ Each card gets its own TipFormBloc from pool
                                        final bloc = _getTipFormBloc(match.id);
                                        
                                        // ✅ Wrap with BlocProvider.value
                                        return BlocProvider<TipFormBloc>.value(
                                          value: bloc,
                                          child: _TipCardInitializer(
                                            matchId: match.id,
                                            userId: userId,
                                            matchDay: match.matchDay,
                                            match: match,
                                            homeTeam: homeTeam,
                                            guestTeam: guestTeam,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ✅ Wrapper Widget um Event nur EINMAL zu triggern
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

      // ✅ NEU: Statistiken beim initialen Laden berechnen
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
    return TipCard(
      key: ValueKey(widget.matchId),
      userId: widget.userId,
      match: widget.match,
      homeTeam: widget.homeTeam,
      guestTeam: widget.guestTeam,
      tip: Tip.empty(widget.userId),
    );
  }
}