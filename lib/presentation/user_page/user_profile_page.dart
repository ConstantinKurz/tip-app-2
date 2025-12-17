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
    return PageTemplate(
      isAuthenticated: isAuthenticated,
      child: BlocBuilder<AuthControllerBloc, AuthControllerState>(
        builder: (context, authState) {
          return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
            builder: (context, teamState) {
              if (authState is! AuthControllerLoaded ||
                  authState.signedInUser == null ||
                  teamState is! TeamsControllerLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            vertical: 48.0, horizontal: 16.0),
                        child: UserProfileForm(
                          user: authState.signedInUser!,
                          teams: teamState.teams,
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Routemaster.of(context).replace('/home');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}