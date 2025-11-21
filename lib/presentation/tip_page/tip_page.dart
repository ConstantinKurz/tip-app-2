import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int? _calculatedScrollIndex;

  int _getCurrentMatchIndex(List<CustomMatch> matches) {
    final now = DateTime.now();
    return matches.indexWhere((match) {
      final matchEndTime = match.matchDate.add(const Duration(minutes: 150));
      return now.isBefore(matchEndTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    const contentMaxWidth = 700.0;
    final horizontalMargin = (screenWidth > contentMaxWidth)
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
                        return Center(
                          child: Text("Tip Failure: ${tipState.tipFailure}"),
                        );
                      }
                      if (matchState is MatchesControllerFailure) {
                        return Center(
                          child:
                              Text("Match Failure: ${matchState.matchFailure}"),
                        );
                      }
                      if (teamState is TeamsControllerFailureState) {
                        return Center(
                          child: Text("Team Failure: ${teamState.teamFailure}"),
                        );
                      }
                      if (authState is AuthControllerFailure) {
                        return Center(
                          child: Text("Auth Failure: ${authState.authFailure}"),
                        );
                      }

                      if (tipState is TipControllerLoaded &&
                          matchState is MatchesControllerLoaded &&
                          teamState is TeamsControllerLoaded &&
                          authState is AuthControllerLoaded) {
                        final matches = matchState.matches;
                        final teams = teamState.teams;
                        final tips = tipState.tips;
                        final userId = authState.signedInUser!.id;
                        final userTips = tips[userId] ?? [];

                        // Bestimme den Scroll-Index:
                        // 1. Aus URL-Parameter (höchste Priorität)
                        // 2. Aus berechnetem aktuellem Spiel
                        if (_calculatedScrollIndex == null) {
                          _calculatedScrollIndex = widget.initialScrollIndex ?? 
                              _getCurrentMatchIndex(matches);
                          
                          // Bereinige URL nach dem ersten Laden
                          if (widget.initialScrollIndex != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Routemaster.of(context).replace('/tips');
                            });
                          }
                        }

                        final scrollIndex = _calculatedScrollIndex!.clamp(0, matches.length - 1);

                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 700),
                              child: ScrollablePositionedList.separated(
                                itemScrollController: _itemScrollController,
                                itemPositionsListener: _itemPositionsListener,
                                initialScrollIndex: scrollIndex,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24.0, horizontal: 16.0),
                                itemCount: matches.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 24),
                                itemBuilder: (context, index) {
                                  final match = matches[index];
                                  final tip = userTips.firstWhere(
                                    (t) => t.matchId == match.id,
                                    orElse: () => Tip.empty(userId)
                                        .copyWith(matchId: match.id),
                                  );
                                  final homeTeam = teams.firstWhere(
                                    (t) => t.id == match.homeTeamId,
                                    orElse: () => Team.empty(),
                                  );
                                  final guestTeam = teams.firstWhere(
                                    (t) => t.id == match.guestTeamId,
                                    orElse: () => Team.empty(),
                                  );
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      final tipId = tip.id.isNotEmpty
                                          ? tip.id
                                          : "${userId}_${match.id}";
                                      
                                      // Navigiere mit dem returnIndex-Parameter
                                      Routemaster.of(context).push(
                                          '/tips-detail/$tipId?from=tip&returnIndex=$index');
                                    },
                                    child: TipCard(
                                      userId: userId,
                                      tip: tip,
                                      homeTeam: homeTeam,
                                      guestTeam: guestTeam,
                                      match: match,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }

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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(right: horizontalMargin, bottom: 16),
        child: ElevatedButton.icon(
          onPressed: () {
            Routemaster.of(context).replace('/home');
          },
          icon: const Icon(Icons.home),
          label: const Text('Home', overflow: TextOverflow.ellipsis),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.onPrimary,
            foregroundColor: themeData.colorScheme.primary,
            textStyle: themeData.textTheme.bodyLarge,
            minimumSize: const Size(140, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
