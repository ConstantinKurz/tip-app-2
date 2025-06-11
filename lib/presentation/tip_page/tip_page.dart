import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_list.dart';

class TipPage extends StatelessWidget {
  final String userId;
  final bool isAuthenticated;
  const TipPage({Key? key, required this.userId, required this.isAuthenticated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => sl<TipControllerBloc>()..add(TipAllEvent())),
        BlocProvider(
            create: (context) =>
                sl<MatchesControllerBloc>()..add(MatchesAllEvent())),
        BlocProvider(
            create: (context) => sl<TeamsBloc>()..add(TeamsAllEvent())),
      ],
      child: Scaffold(
        body: BlocBuilder<TipControllerBloc, TipControllerState>(
          builder: (context, tipState) {
            return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
              builder: (context, matchState) {
                return BlocBuilder<TeamsBloc, TeamsState>(
                  builder: (context, teamState) {
                    if (tipState is TipControllerFailure) {
                      return Center(
                          child: Text("Tip Failure: ${tipState.tipFailure}"));
                    }
                    if (matchState is MatchesControllerFailure) {
                      return Center(
                          child: Text(
                              "Match Failure: ${matchState.matchFailure}"));
                    }
                    if (teamState is TeamFailureState) {
                      return Center(
                          child:
                              Text("Team Failure: ${teamState.teamFailure}"));
                    }

                    if (tipState is TipControllerLoaded &&
                        matchState is MatchesControllerLoaded &&
                        teamState is TeamsLoaded) {
                      final userTips = tipState.tips[userId] ?? [];

                      return PageTemplate(
                        isAuthenticated: isAuthenticated,
                        child: TipList(
                          userId: userId,
                          tips: userTips,
                          teams: teamState.teams,
                          matches: matchState.matches,
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
      ),
    );
  }
}
