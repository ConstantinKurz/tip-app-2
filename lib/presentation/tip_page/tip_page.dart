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

class TipPage extends StatefulWidget {
  final bool isAuthenticated;

  const TipPage({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _matchKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMatch(List<CustomMatch> matches) {
    final now = DateTime.now();
    int currentMatchIndex = -1;

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final matchEndTime = match.matchDate.add(const Duration(minutes: 150));

      if (now.isBefore(matchEndTime)) {
        currentMatchIndex = i;
        break;
      }
    }

    if (currentMatchIndex != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _matchKeys[matches[currentMatchIndex].id]?.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
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
                        final tips = tipState.tips;
                        final userId = authState.signedInUser!.id;
                        final userTips = tips[userId] ?? [];
                        final teams = teamState.teams;
                        _scrollToCurrentMatch(matches);

                        return PageTemplate(
                          isAuthenticated: widget.isAuthenticated,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 700),
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24.0, horizontal: 16.0),
                                itemCount: matches.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 24),
                                itemBuilder: (context, index) {
                                  final match = matches[index];
                                  _matchKeys[match.id] = GlobalKey();
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

                                  return Container(
                                    key: _matchKeys[match.id],
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        final tipId = tip.id.isNotEmpty
                                            ? tip.id
                                            : "${userId}_${match.id}";
                                        Routemaster.of(context)
                                            .push('/tips-detail/$tipId');
                                      },
                                      child: TipCard(
                                        userId: userId,
                                        tip: tip,
                                        homeTeam: homeTeam,
                                        guestTeam: guestTeam,
                                        match: match,
                                      ),
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
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
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
