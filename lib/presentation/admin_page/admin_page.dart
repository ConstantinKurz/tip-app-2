import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/presentation/admin_page/widget/match_list.dart';
import 'package:flutter_web/presentation/admin_page/widget/team_list.dart';
import 'package:flutter_web/presentation/admin_page/widget/user_list.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class AdminPage extends StatefulWidget {
  static String adminPagePath = "/admin";
  final bool isAuthenticated;

  AdminPage({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthControllerBloc, AuthControllerState>(
      builder: (context, authState) {
        return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
          builder: (context, matchState) {
            return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
              builder: (context, teamState) {
                if (authState is! AuthControllerLoaded ||
                    matchState is! MatchesControllerLoaded ||
                    teamState is! TeamsControllerLoaded) {
                  return PageTemplate(
                    isAuthenticated: widget.isAuthenticated,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                return PageTemplate(
                  isAuthenticated: widget.isAuthenticated,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.ease,
                                );
                              },
                            ),
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                children: [
                                  UserList(
                                    users: authState.users,
                                    matches: matchState.matches,
                                    teams: teamState.teams,
                                  ),
                                  MatchList(
                                    matches: matchState.matches,
                                    teams: teamState.teams,
                                  ),
                                  TeamList(teams: teamState.teams),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.ease,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
