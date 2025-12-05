import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/presentation/core/forms/user_profile_form.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

class UserProfilePage extends StatelessWidget {
  static const String userProfilePagePath = "/profile";
  final bool isAuthenticated;

  const UserProfilePage({
    Key? key,
    required this.isAuthenticated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: PageTemplate(
        isAuthenticated: isAuthenticated,
        child: BlocBuilder<AuthControllerBloc, AuthControllerState>(
          builder: (context, authState) {
            if (authState is! AuthControllerLoaded ||
                authState.signedInUser == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
              builder: (context, teamState) {
                if (teamState is! TeamsControllerLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    Center(
                      child: Container(
                        width: screenWidth > 700 ? 700 : screenWidth * 0.9,
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.85,
                          minHeight: 650,
                        ),
                        padding: const EdgeInsets.all(40.0),
                        child: SingleChildScrollView(
                          child: UserProfileForm(
                            user: authState.signedInUser!,
                            teams: teamState.teams,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      right: screenWidth > 700 ? (screenWidth - 700) / 2 + 16 : screenWidth * 0.05 + 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 28, color: Colors.white),
                          onPressed: () {
                            Routemaster.of(context).replace('/home');
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}