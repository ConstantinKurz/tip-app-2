import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_date_picker.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_time_picker.dart';
import 'dart:core';

class CreateMatchForm extends StatelessWidget {
  late final List<Team> teams;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  CreateMatchForm({super.key, required this.teams});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    String? validateTeam(String? input) {
      if (input == null) {
        return "Bitte wählen Sie ein Team";
      } else {
        return null;
      }
    }

    String? validateMatchDay(int? input) {
      if (input == null) {
        return "Bitte wählen Sie einen Match Tag";
      } else {
        return null;
      }
    }

    return BlocConsumer<MatchesformBloc, MatchesformState>(
      listenWhen: (p, c) =>
          p.matchFailureOrSuccessOption != c.matchFailureOrSuccessOption,
      listener: (context, state) {
        state.matchFailureOrSuccessOption!.fold(
          () {},
          (either) => either.fold(
            (failure) =>
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Fehler beim Erstellen"),
              backgroundColor: Colors.red,
            )),
            (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Match erfolgreich erstellt"),
              backgroundColor: Colors.green,
            )),
          ),
        );
      },
      builder: (context, state) {
        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButtonFormField<Team>(
                value: state.homeTeamId == null
                    ? null
                    : teams.firstWhere((t) => t.id == state.homeTeamId,
                        orElse: () => Team.empty()),
                decoration: const InputDecoration(labelText: 'Home Team'),
                items: teams
                    .map((team) =>
                        DropdownMenuItem(value: team, child: Text(team.name)))
                    .toList(),
                validator: (value) => validateTeam(value?.id),
                onChanged: (team) {
                  context
                      .read<MatchesformBloc>()
                      .add(MatchFormFieldUpdatedEvent(homeTeamId: team?.id));
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Team>(
                value: state.guestTeamId == null
                    ? null
                    : teams.firstWhere((t) => t.id == state.guestTeamId,
                        orElse: () => Team.empty()),
                decoration: const InputDecoration(labelText: 'Gast Team'),
                validator: (value) => validateTeam(value?.id),
                items: teams
                    .map((team) =>
                        DropdownMenuItem(value: team, child: Text(team.name)))
                    .toList(),
                onChanged: (team) {
                  context
                      .read<MatchesformBloc>()
                      .add(MatchFormFieldUpdatedEvent(guestTeamId: team?.id));
                },
              ),
              const SizedBox(height: 16),
              // TODO: add current date as default
              Row(
                children: [
                  Expanded(
                    child: CustomDatePickerField(
                      initialDate: state.matchDate ?? DateTime.now(),
                      onDateChanged: (date) {
                        context
                            .read<MatchesformBloc>()
                            .add(MatchFormFieldUpdatedEvent(matchDate: date));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTimePickerField(
                      initialTime: state.matchTime ?? TimeOfDay.now(),
                      onTimeChanged: (time) {
                        context
                            .read<MatchesformBloc>()
                            .add(MatchFormFieldUpdatedEvent(matchTime: time));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                validator: validateMatchDay,
                value: state.matchDay,
                decoration: const InputDecoration(labelText: 'Match Tag'),
                items: List.generate(8, (i) => i + 1) // 1 bis 8, je nach Turnierstruktur
                    .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(CustomMatch.empty().getStageName),
                        ))
                    .toList(),
                onChanged: (day) {
                  context
                      .read<MatchesformBloc>()
                      .add(MatchFormFieldUpdatedEvent(matchDay: day));
                },
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    buttonText: 'Speichern',
                    borderColor: primaryDark,
                    backgroundColor: themeData.colorScheme.primaryContainer,
                    hoverColor: primaryDark,
                    callback: () {
                      if (formKey.currentState!.validate()) {
                        final combinedDateTime = DateTime(
                          state.matchDate!.year,
                          state.matchDate!.month,
                          state.matchDate!.day,
                          state.matchTime!.hour,
                          state.matchTime!.minute,
                        );

                        context.read<MatchesformBloc>().add(
                              CreateMatchEvent(
                                id: "${state.homeTeamId}vs${state.guestTeamId}_${state.matchDay}",
                                homeTeamId: state.homeTeamId,
                                guestTeamId: state.guestTeamId,
                                matchDate: combinedDateTime,
                                matchDay: state.matchDay,
                              ),
                            );
                      } else {
                        context.read<MatchesformBloc>().add(CreateMatchEvent(
                              id: null,
                              homeTeamId: null,
                              guestTeamId: null,
                              matchDate: null,
                              matchDay: null,
                            ));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    borderColor: primaryDark,
                    hoverColor: primaryDark,
                    backgroundColor: themeData.colorScheme.primaryContainer,
                    buttonText: 'Abbrechen',
                    callback: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
