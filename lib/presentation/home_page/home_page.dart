import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import '../../domain/entities/team.dart';
import '../../injections.dart';
import '../core/buttons/add_button.dart';
import '../core/dialogs/create_match_dialog.dart';

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
                  if (authState is AuthControllerLoading &&
                      matchState is MatchesControllerLoading &&
                      teamState is TeamsLoading) {
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
                      child: ListView(
                        children: [
                          Text('Users:',
                              style: Theme.of(context).textTheme.headline6),
                          ...authState.users.map((user) {
                            return ListTile(
                              title: Text('User: ${user.username}'),
                              subtitle: Text('Email: ${user.email}'),
                            );
                          }).toList(),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Matches:',
                                  style: Theme.of(context).textTheme.headline6),
                              AddButton(
                                  onPressed: () =>
                                      _showAddMatchDialog(context, teamState.teams)),
                            ],
                          ),
                          ...matchState.matches.map((match) {
                            return ListTile(
                              title: Text(
                                  'Match: ${match.homeTeamId.value} vs ${match.guestTeamId.value}'),
                              subtitle: Text('Date: ${match.matchDate}'),
                            );
                          }).toList(),
                        ],
                      ),
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

void _showAddMatchDialog(BuildContext context, List<Team> teams) {
  showDialog(
    barrierColor: Colors.transparent,
    context: context,
    builder: (BuildContext context) {
      return Builder(
        builder: (BuildContext newContext) {
          return CreateMatchDialog(teams: teams);
        },
      );
    },
  );
}
