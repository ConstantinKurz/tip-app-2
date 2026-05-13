import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

class AdminTeamDeletePage extends StatelessWidget {
  final String teamId;

  const AdminTeamDeletePage({
    Key? key,
    required this.teamId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageTemplate(
      isAuthenticated: true,
      child: BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
        builder: (context, teamState) {
          if (teamState is! TeamsControllerLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final team = teamState.teams.firstWhere(
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

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.primaryContainer,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Routemaster.of(context).pop(),
              ),
              title: Text(
                'Team löschen',
                style: theme.textTheme.titleLarge,
              ),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: BlocProvider<TeamsformBloc>(
                    create: (context) => sl<TeamsformBloc>(),
                    child: _DeleteContent(team: team),
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

class _DeleteContent extends StatelessWidget {
  final Team team;

  const _DeleteContent({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentString =
        'Soll das Team ${team.name} wirklich gelöscht werden?';

    return BlocConsumer<TeamsformBloc, TeamsformState>(
      listenWhen: (p, c) =>
          p.teamFailureOrSuccessOption != c.teamFailureOrSuccessOption,
      listener: (context, state) {
        state.teamFailureOrSuccessOption?.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(
                  'Fehler beim Löschen des Teams',
                  style: theme.textTheme.bodyLarge,
                ),
              ));
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  'Team gelöscht!',
                  style: theme.textTheme.bodyLarge,
                ),
              ));
              Routemaster.of(context).pop();
            },
          ),
        );
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team löschen',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(
                contentString,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      hoverColor: primaryDark,
                      borderColor: primaryDark,
                      buttonText: 'Abbrechen',
                      callback: () => Routemaster.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      hoverColor: Colors.red,
                      borderColor: Colors.red,
                      buttonText: 'Löschen',
                      callback: () {
                        BlocProvider.of<TeamsformBloc>(context)
                            .add(TeamFormDeleteEvent(id: team.id));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
