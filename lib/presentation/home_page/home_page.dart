import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/ranking/ranking_bloc.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:flutter_web/presentation/home_page/widget/ranking_section.dart';
import 'package:flutter_web/presentation/home_page/widget/upcoming_tips.dart';
import 'package:routemaster/routemaster.dart';

class HomePage extends StatefulWidget {
  static const String homePagePath = "/home";
  final bool isAuthenticated;

  const HomePage({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _rankingSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    const contentMaxWidth = 700.0;
    final horizontalMargin = (screenWidth > contentMaxWidth)
        ? (screenWidth - contentMaxWidth) / 2
        : 16.0;

    return BlocProvider(
      create: (_) => sl<RankingBloc>(),
      child: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        builder: (context, authState) {
          if (authState is! AuthControllerLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final userId = authState.signedInUser?.id ?? '';
          final users = authState.users;

          return Scaffold(
            body: PageTemplate(
              isAuthenticated: widget.isAuthenticated,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BlocProvider(
                          create: (_) => sl<RankingBloc>(),
                          child: BlocListener<RankingBloc, RankingState>(
                            listener: (context, state) {
                              if (!state.expanded) {
                                Scrollable.ensureVisible(
                                  _rankingSectionKey.currentContext!,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: RankingSection(userId: userId, users: users),
                          ),
                        ),
                        UpcomingTipSection(
                          userId: userId,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            floatingActionButton: Padding(
              padding: EdgeInsets.only(right: horizontalMargin, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Routemaster.of(context).push('/tips');
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Tipps', overflow: TextOverflow.ellipsis),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.onPrimary,
                  foregroundColor: themeData.colorScheme.primary,
                  textStyle: themeData.textTheme.bodyLarge,
                  minimumSize: const Size(140, 48),
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
      ),
    );
  }
}
