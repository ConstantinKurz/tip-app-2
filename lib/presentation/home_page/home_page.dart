import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_bloc.dart';
import 'package:flutter_web/presentation/core/dialogs/match_dialog.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/widget/match_list.dart';
import 'package:flutter_web/presentation/home_page/widget/user_list.dart';
import '../../domain/entities/team.dart';
import '../../injections.dart';

class HomePage extends StatelessWidget {
  static String homePagePath = "/home";
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AuthControllerBloc>()..add(AuthAllEvent()),
        ),
        BlocProvider(
          create: (context) =>
              sl<MatchesControllerBloc>()..add(MatchesAllEvent()),
        ),
        BlocProvider(
          create: (context) => sl<TeamsBloc>()..add(TeamsAllEvent()),
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
            builder: (context, authState) {
          return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
            builder: (context, matchState) {
              return BlocBuilder<TeamsBloc, TeamsState>(
                builder: (context, teamState) {
                  if (authState is AuthControllerLoading ||
                      matchState is MatchesControllerLoading ||
                      teamState is TeamsLoading) {
                    print(authState);
                    print(matchState);
                    print(teamState);
                    return Center(
                      child: CircularProgressIndicator(
                        color: themeData.colorScheme.secondary,
                      ),
                    );
                  } else if (authState is AuthControllerFailure) {
                    return Center(
                        child: Text("Auth Failure: ${authState.authFailure}"));
                  } else if (matchState is MatchesControllerFailure) {
                    return Center(
                        child:
                            Text("Match Failure: ${matchState.matchFailure}"));
                  } else if (teamState is TeamFailureState) {
                    return Center(
                        child: Text(" Team Failure: ${teamState.teamFailure}"));
                  } else if (authState is AuthControllerLoaded &&
                      matchState is MatchesControllerLoaded &&
                      teamState is TeamsLoaded) {
                    return PageTemplate(
                      child: SingleChildScrollView(
                        child: Column( 
                          children: [
                            // Expanded(child
                            SizedBox(
                              height: 300,
                              child: UserList(
                                    matches: matchState.matches,
                                    teams: teamState.teams,
                                    users: authState.users),
                            ),
                            // ),
                            const SizedBox(height: 16,),
                            // Expanded( child:
                            SizedBox(
                              // height: 10000,
                              child: MatchList(
                                    matches: matchState.matches,
                                    teams: teamState
                                        .teams),
                            ), // Übergib die Liste der Matches
                            // ),
                          ],
                        ),
                      )
                    );
                  }
                  return Container(); // Default empty container
                },
              );
            },
          );
        }),
      ),
    );
  }
}
