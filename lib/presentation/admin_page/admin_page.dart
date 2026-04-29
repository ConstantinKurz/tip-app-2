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

  const AdminPage({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    setState(() {
      _currentPageIndex = _pageController.page?.round() ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
                  child: isMobile
                      ? _buildMobileLayout(context, authState, matchState, teamState)
                      : _buildDesktopLayout(context, authState, matchState, teamState),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Builds mobile-optimized layout with bottom tabs
  Widget _buildMobileLayout(
    BuildContext context,
    AuthControllerLoaded authState,
    MatchesControllerLoaded matchState,
    TeamsControllerLoaded teamState,
  ) {
    return Column(
      children: [
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
        // Bottom tab indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton(0, 'Nutzer'),
              const SizedBox(width: 12),
              _buildTabButton(1, 'Matches'),
              const SizedBox(width: 12),
              _buildTabButton(2, 'Teams'),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds desktop layout with side navigation
  Widget _buildDesktopLayout(
    BuildContext context,
    AuthControllerLoaded authState,
    MatchesControllerLoaded matchState,
    TeamsControllerLoaded teamState,
  ) {
    return Column(
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
    );
  }

  /// Builds a tab button for mobile navigation
  Widget _buildTabButton(int index, String label) {
    final isActive = _currentPageIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
