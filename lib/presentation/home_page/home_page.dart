import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/widget/match_list.dart';
import 'package:flutter_web/presentation/home_page/widget/team_list.dart';
import 'package:flutter_web/presentation/home_page/widget/user_list.dart';
import '../../injections.dart';

class HomePage extends StatelessWidget {
  static String homePagePath = "/home";
  final bool isAuthenticated;
  HomePage({Key? key, required this.isAuthenticated}) : super(key: key);

  final CarouselController _carouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.width;
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
                    return Center(
                      child: CircularProgressIndicator(
                        color: themeData.colorScheme.onPrimaryContainer,
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
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.ease);
                                  },
                                ),
                                Expanded(
                                  child: SizedBox(
                                    child: CarouselSlider(
                                      carouselController: _carouselController,
                                      options: CarouselOptions(
                                        scrollPhysics:
                                            const NeverScrollableScrollPhysics(),
                                        viewportFraction: .6,
                                        height: screenHeight,
                                        initialPage: 2,
                                        enableInfiniteScroll: false,
                                        enlargeCenterPage: false,
                                        onPageChanged: (_, __) {},
                                      ),
                                      items: [
                                        MatchList(
                                            matches: matchState.matches,
                                            teams: teamState.teams),
                                        UserList(
                                            matches: matchState.matches,
                                            teams: teamState.teams,
                                            users: authState.users),
                                        TeamList(teams: teamState.teams)
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.arrow_forward_ios_outlined),
                                  onPressed: () {
                                    _carouselController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.ease);
                                  },
                                ),
                              ],
                            ),
                          ),
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
