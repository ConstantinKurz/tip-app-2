import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/domain/entities/user.dart';
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
                          child: Text("Match Failure: ${matchState.matchFailure}"),
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
                        
                        final teams = teamState.teams;
                        final matches = matchState.matches;
                        final tips = tipState.tips;
                        final userTips = tips[widget.selectedUserId] ?? [];
                        
                        final filteredMatches = _filteredMatches.isNotEmpty || matches.isEmpty 
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
                                      padding: const EdgeInsets.only(top: 60, bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Tipps von ${selectedUser.name}",
                                            style: themeData.textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Rang: #${selectedUser.rank} • Punkte: ${selectedUser.score} • Joker: ${selectedUser.jokerSum}",
                                            style: themeData.textTheme.bodyMedium?.copyWith(
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
                                      hintText: "Nach Teams, Spielphase oder Matchtag suchen...",
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
                                          constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                                          child: ScrollablePositionedList.separated(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16.0,
                                              horizontal: 16.0,
                                            ),
                                            itemCount: filteredMatches.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 24),
                                            itemBuilder: (context, index) {
                                              final match = filteredMatches[index];
                                              final tip = userTips.firstWhere(
                                                (t) => t.matchId == match.id,
                                                orElse: () => Tip.empty(widget.selectedUserId)
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

                                              return TipCard(
                                                userId: widget.selectedUserId,
                                                tip: tip,
                                                homeTeam: homeTeam,
                                                guestTeam: guestTeam,
                                                match: match,
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
                                top: 48,
                                right: horizontalMargin,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 28, color: Colors.white),
                                    onPressed: () {
                                      Routemaster.of(context).replace('/admin');
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
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