import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/controller/matchescontroller_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/application/teams/controller/teams_controller_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/page_wrapper/page_template.dart';
import 'package:routemaster/routemaster.dart';

class AdminMatchDeletePage extends StatelessWidget {
  final String matchId;

  const AdminMatchDeletePage({
    Key? key,
    required this.matchId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageTemplate(
      isAuthenticated: true,
      child: BlocBuilder<MatchesControllerBloc, MatchesControllerState>(
        builder: (context, matchState) {
          return BlocBuilder<TeamsControllerBloc, TeamsControllerState>(
            builder: (context, teamState) {
              if (matchState is! MatchesControllerLoaded ||
                  teamState is! TeamsControllerLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final match = matchState.matches.firstWhere(
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

              final homeTeam = teamState.teams.firstWhere(
                (t) => t.id == match.homeTeamId,
                orElse: () => Team.empty(),
              );
              final guestTeam = teamState.teams.firstWhere(
                (t) => t.id == match.guestTeamId,
                orElse: () => Team.empty(),
              );

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Routemaster.of(context).pop(),
                  ),
                  title: Text(
                    'Match löschen',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: BlocProvider<MatchesformBloc>(
                        create: (context) => sl<MatchesformBloc>(),
                        child: _DeleteContent(
                          match: match,
                          homeTeamName: homeTeam.name,
                          guestTeamName: guestTeam.name,
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

class _DeleteContent extends StatelessWidget {
  final CustomMatch match;
  final String homeTeamName;
  final String guestTeamName;

  const _DeleteContent({
    required this.match,
    required this.homeTeamName,
    required this.guestTeamName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentString =
        'Soll das Match $homeTeamName vs $guestTeamName an Spieltag ${match.matchDay} wirklich gelöscht werden?';

    return BlocConsumer<MatchesformBloc, MatchesformState>(
      listenWhen: (p, c) =>
          p.matchFailureOrSuccessOption != c.matchFailureOrSuccessOption,
      listener: (context, state) {
        state.matchFailureOrSuccessOption?.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text(
                  'Fehler beim Löschen des Matches',
                  style: theme.textTheme.bodyLarge,
                ),
              ));
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  'Match gelöscht!',
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
                'Match löschen',
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
                        BlocProvider.of<MatchesformBloc>(context)
                            .add(MatchFormDeleteEvent(id: match.id));
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
