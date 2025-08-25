import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/presentation/core/buttons/custom_bottom_buttons.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_section.dart';
import 'package:flutter_web/presentation/home_page/widget/upcoming_tips.dart';
//import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  static const String homePagePath = "/home";
  final bool isAuthenticated;

  const HomePage({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<AuthControllerBloc, AuthControllerState>(
      builder: (context, authState) {
        if (authState is! AuthControllerLoaded ||
            authState.signedInUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final userId = authState.signedInUser!.name;
        final users = authState.users;

        return Scaffold(
          body: PageTemplate(
            isAuthenticated: isAuthenticated,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: RankingSection(userId: userId, users: users),
                      ),
                    ),
                    SizedBox(
                      width: screenWidth * 0.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: UpcomingTipSection(userId: userId),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomButtons(
            buttons: [
              ButtonConfig(
                label: 'Dashboard',
                route: '/dashboard',
                icon: Icons.dashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.onPrimary,
                  foregroundColor: themeData.colorScheme.primary,
                  textStyle: themeData.textTheme.bodyLarge,
                ),
              ),
              ButtonConfig(
                label: 'Tipps',
                route: '/tips-detail',
                icon: Icons.list_alt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.onPrimary,
                  foregroundColor: themeData.colorScheme.primary,
                  textStyle: themeData.textTheme.bodyLarge,
                ),
              ),
            ],
          ),

          // Falls du das PDF-Button wieder aktivieren willst:
          // floatingActionButton: Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: TextButton.icon(
          //     onPressed: () async {
          //       const url = 'https://dein-server.de/regeln.pdf';
          //       final uri = Uri.parse(url);
          //       if (await canLaunchUrl(uri)) {
          //         await launchUrl(uri);
          //       }
          //     },
          //     icon: const Icon(Icons.picture_as_pdf),
          //     label: const Text('Regeln ansehen'),
          //   ),
          // ),
        );
      },
    );
  }
}
