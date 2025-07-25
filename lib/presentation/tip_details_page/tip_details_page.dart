import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/tips/controller/tipscontroller_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/tip_details_page/tip_details_list.dart';
import 'package:flutter_web/presentation/tip_details_page/tip_swipe_view.dart';
import 'package:flutter_web/presentation/tip_page/widgets/tip_list.dart';

class TipDetailsPage extends StatelessWidget {
  final bool isAuthenticated;

  const TipDetailsPage({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
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
                      final userTips =
                          tipState.tips[authState.signedInUser!.username] ?? [];

                      return PageTemplate(
                        isAuthenticated: isAuthenticated,
                        child: TipsSwipeView(
                          userId: authState.signedInUser!.username,
                          tips: userTips,
                          teams: teamState.teams,
                          matches: matchState.matches,
                          //showSearchBar: true,
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
    ));
  }
}
