import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/controller/authcontroller_bloc.dart';
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/forms/admin_create_user_form.dart';
import 'package:flutter_web/presentation/core/forms/update_user_form.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

enum UserFormAction { create, update }

class AdminUserFormPage extends StatelessWidget {
  final UserFormAction action;
  final String? userId;

  const AdminUserFormPage({
    Key? key,
    required this.action,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageTemplate(
      isAuthenticated: true,
      child: BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
        builder: (context, teamState) {
          return BlocBuilder<AuthControllerBloc, AuthControllerState>(
            builder: (context, authState) {
              if (teamState is! TeamsControllerLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final teams = teamState.teams;

              // For update action, get the user
              AppUser? user;
              if (action == UserFormAction.update && userId != null) {
                if (authState is! AuthControllerLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                user = authState.users.firstWhere(
                  (u) => u.id == userId,
                  orElse: () => AppUser.empty(),
                );
                if (user.id.isEmpty) {
                  return Center(
                    child: Text(
                      'User nicht gefunden',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }
              }

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Routemaster.of(context).pop(),
                  ),
                  title: Text(
                    action == UserFormAction.create
                        ? 'Neuen User erstellen'
                        : 'User bearbeiten',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: BlocProvider<AuthformBloc>(
                        create: (context) => sl<AuthformBloc>(),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white),
                          ),
                          child: action == UserFormAction.create
                              ? const CreateUserForm()
                              : UpdateUserForm(user: user!, teams: teams),
                        ),
                      ),
                    ),
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
