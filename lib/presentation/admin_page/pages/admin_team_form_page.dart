import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/forms/create_team_form.dart';
import 'package:flutter_web/presentation/core/forms/update_team_form.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

enum TeamFormAction { create, update }

class AdminTeamFormPage extends StatelessWidget {
  final TeamFormAction action;
  final String? teamId;

  const AdminTeamFormPage({
    Key? key,
    required this.action,
    this.teamId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageTemplate(
      isAuthenticated: true,
      child: BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
        builder: (context, teamState) {
          // For update action, get the team
          Team? team;
          if (action == TeamFormAction.update && teamId != null) {
            if (teamState is! TeamsControllerLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            team = teamState.teams.firstWhere(
              (t) => t.id == teamId,
              orElse: () => Team.empty(),
            );
            if (team.id.isEmpty) {
              return Center(
                child: Text(
                  'Team nicht gefunden',
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
                action == TeamFormAction.create
                    ? 'Neues Team erstellen'
                    : 'Team bearbeiten',
                style: theme.textTheme.titleLarge,
              ),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: BlocProvider<TeamsformBloc>(
                    create: (context) => sl<TeamsformBloc>(),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: action == TeamFormAction.create
                          ? const CreateTeamForm()
                          : UpdateTeamForm(team: team!),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
