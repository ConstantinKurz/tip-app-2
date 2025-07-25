import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_list.dart';

class TipPage extends StatelessWidget {
  final String userId;
  final bool isAuthenticated;

  const TipPage({
    Key? key,
    required this.userId,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  // TODO: remove blocs
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TipControllerBloc, TipControllerState>(
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

                  if (tipState is TipControllerLoaded &&
                      matchState is MatchesControllerLoaded &&
                      teamState is TeamsControllerLoaded) {
                    final userTips = tipState.tips[userId] ?? [];

                    return PageTemplate(
                      isAuthenticated: isAuthenticated,
                      child: TipList(
                        userId: userId,
                        tips: userTips,
                        teams: teamState.teams,
                        matches: matchState.matches,
                        showSearchBar: true,
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
      ),
    );
  }
}
