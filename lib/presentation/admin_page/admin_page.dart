import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/presentation/admin_page/widget/match_list.dart';
import 'package:flutter_web/presentation/admin_page/widget/team_list.dart';
import 'package:flutter_web/presentation/admin_page/widget/user_list.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';

class AdminPage extends StatelessWidget {
  static String adminPagePath = "/admin";
  final bool isAuthenticated;

  AdminPage({Key? key, required this.isAuthenticated}) : super(key: key);

  final CarouselController _carouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final themeData = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        builder: (context, authState) {
          return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
            builder: (context, matchState) {
              return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
                builder: (context, teamState) {
                  if (authState is AuthControllerLoading ||
                      matchState is MatchesControllerLoading ||
                      teamState is TeamsControllerLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: themeData.colorScheme.onPrimaryContainer,
                      ),
                    );
                  }

                  if (authState is AuthControllerFailure) {
                    return Center(
                      child: Text("Auth Failure: ${authState.authFailure}"),
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

                  if (authState is AuthControllerLoaded &&
                      matchState is MatchesControllerLoaded &&
                      teamState is TeamsControllerLoaded) {
                    return PageTemplate(
                      isAuthenticated: isAuthenticated,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                  onPressed: () {
                                    _carouselController.previousPage(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.ease,
                                    );
                                  },
                                ),
                                Expanded(
                                  child: CarouselSlider(
                                    carouselController: _carouselController,
                                    options: CarouselOptions(
                                      scrollPhysics: const NeverScrollableScrollPhysics(),
                                      viewportFraction: .6,
                                      height: screenWidth,
                                      initialPage: 2,
                                      enableInfiniteScroll: false,
                                      enlargeCenterPage: false,
                                    ),
                                    items: [
                                      MatchList(
                                        matches: matchState.matches,
                                        teams: teamState.teams,
                                      ),
                                      UserList(
                                        matches: matchState.matches,
                                        teams: teamState.teams,
                                        users: authState.users,
                                      ),
                                      TeamList(teams: teamState.teams),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios_outlined),
                                  onPressed: () {
                                    _carouselController.nextPage(
                                      duration: const Duration(milliseconds: 300),
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
                  }

                  return const SizedBox(); // Fallback
                },
              );
            },
          );
        },
      ),
    );
  }
}
