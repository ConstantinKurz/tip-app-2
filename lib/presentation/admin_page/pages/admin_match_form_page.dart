import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/forms/create_match_form.dart';
import 'package:flutter_web/presentation/core/forms/update_match_form.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

enum MatchFormAction { create, update }

class AdminMatchFormPage extends StatelessWidget {
  final MatchFormAction action;
  final String? matchId;

  const AdminMatchFormPage({
    Key? key,
    required this.action,
    this.matchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageTemplate(
      isAuthenticated: true,
      child: BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
        builder: (context, teamState) {
          return BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
            builder: (context, matchState) {
              if (teamState is! TeamsControllerLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final teams = teamState.teams;

              // For update action, get the match
              CustomMatch? match;
              if (action == MatchFormAction.update && matchId != null) {
                if (matchState is! MatchesControllerLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                match = matchState.matches.firstWhere(
                  (m) => m.id == matchId,
                  orElse: () => CustomMatch.empty(),
                );
                if (match.id.isEmpty) {
                  return Center(
                    child: Text(
                      'Match nicht gefunden',
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
                    action == MatchFormAction.create
                        ? 'Neues Match erstellen'
                        : 'Match bearbeiten',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: BlocProvider<MatchesformBloc>(
                        create: (context) => sl<MatchesformBloc>(),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white),
                          ),
                          child: action == MatchFormAction.create
                              ? CreateMatchForm(teams: teams)
                              : UpdateMatchForm(teams: teams, match: match!),
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
