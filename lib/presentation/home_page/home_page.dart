import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_section.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  static const String homePagePath = "/home";
  final bool isAuthenticated;

  const HomePage({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return MultiBlocProvider(
      providers: [
        // BlocProvider(
        //   create: (context) => sl<AuthControllerBloc>()..add(AuthAllEvent()),
        // ),
        BlocProvider(
          create: (context) => sl<MatchesControllerBloc>()..add(MatchesAllEvent()),
        ),
        BlocProvider(
          create: (context) => sl<TeamsControllerBloc>()..add(TeamsControllerAllEvent()),
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
          builder: (context, matchState) {
            return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
              builder: (context, teamState) {
                if (
                    matchState is MatchesControllerLoading ||
                    teamState is TeamsControllerLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: themeData.colorScheme.onPrimaryContainer,
                    ),
                  );
                }
        
                if (
                    matchState is MatchesControllerLoaded &&
                    teamState is TeamsControllerLoaded) {
                  return PageTemplate(
                    isAuthenticated: isAuthenticated,
                    child: Center( 
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: screenWidth * 0.5,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: RankingSection(),
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 0.5,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Placeholder(), // UpcomingMatchesPreview()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
        
                return const SizedBox(); // fallback
              },
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton.icon(
            onPressed: () async {
              const url = 'https://dein-server.de/regeln.pdf';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Regeln ansehen'),
          ),
        ),
      ),
    );
  }
}
