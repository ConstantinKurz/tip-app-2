import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class HomePage extends StatelessWidget {
  static String homePagePath = "/home";
  final bool isAuthenticated;
  HomePage({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.width;
    final themeData = Theme.of(context);
    return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                sl<MatchesControllerBloc>()..add(MatchesAllEvent()),
          ),
          BlocProvider(
            create: (context) => sl<TeamsControllerBloc>()..add(TeamsControllerAllEvent()),
          ),
        ],
        child: Scaffold(body:
            BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
                builder: (context, matchState) {
          return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
              builder: (context, teamState) {
            if (matchState is MatchesControllerLoading ||
                teamState is TeamsControllerLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: themeData.colorScheme.onPrimaryContainer,
                ),
              );
            }
            return PageTemplate(
              isAuthenticated: isAuthenticated,
              child: Placeholder(),
            );
          });
        })));
  }
}
