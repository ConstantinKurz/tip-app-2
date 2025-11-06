import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_section.dart';
import 'package:flutter_web/presentation/home_page/widget/upcoming_tips.dart';
import 'package:routemaster/routemaster.dart';

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

        final userId = authState.signedInUser!.id;
        final users = authState.users;

        final double contentWidth =
            screenWidth > 600 ? screenWidth * 0.5 : screenWidth * 0.9;
        final double horizontalMargin = (screenWidth - contentWidth) / 2;

        return Scaffold(
          body: PageTemplate(
            isAuthenticated: isAuthenticated,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: RankingSection(userId: userId, users: users),
                      ),
                    ),
                    SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: UpcomingTipSection(
                          userId: userId,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: Padding(
            padding: EdgeInsets.only(right: horizontalMargin),
            child: ElevatedButton.icon(
              onPressed: () {
                Routemaster.of(context).push('/tips-detail');
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Tipps', overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.onPrimary,
                foregroundColor: themeData.colorScheme.primary,
                textStyle: themeData.textTheme.bodyLarge,
                minimumSize: Size(contentWidth*.2, contentWidth*.1/2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
