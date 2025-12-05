import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_date_picker.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_time_picker.dart';

class UpdateMatchForm extends StatelessWidget {
  final List<Team> teams;
  final CustomMatch match;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController homeScoreController = TextEditingController();
  final TextEditingController guestScoreController = TextEditingController();

  UpdateMatchForm({Key? key, required this.teams, required this.match})
      : super(key: key);

  String? _validateScore(String? value, MatchesformState state,
      BuildContext context, String scoreType) {
    if (value == null || value.isEmpty) {
      // Access the other score from the state
      if ((state.homeScore == null && scoreType == 'guest') ||
          (state.guestScore == null && scoreType == 'home')) {
        return '[0-10]';
      }
      return null;
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 10) {
      return '[0-10]';
    }
    // No need to update local score variables, the bloc will handle it
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    homeScoreController.text = match.homeScore?.toString() ?? '';
    guestScoreController.text = match.guestScore?.toString() ?? '';

    return BlocConsumer<MatchesformBloc, MatchesformState>(
      listenWhen: (previous, current) =>
          previous.matchFailureOrSuccessOption !=
          current.matchFailureOrSuccessOption,
      listener: (context, state) {
        state.matchFailureOrSuccessOption!.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    "Fehler beim Aktualisieren des Matches",
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              );
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    "Match erfolgreich aktualisiert!",
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              );
              Navigator.of(context).pop(); // Close on success
            },
          ),
        );
      },
      builder: (context, state) {
        final allMatchDays = <int>{
          match.matchDay,
          if (state.matchDay != null) state.matchDay!,
          ...List.generate(8, (i) => i),
        }.toList()
          ..sort();

        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Team>(
                      decoration: const InputDecoration(labelText: 'Home Team'),
                      value: teams.firstWhere((t) => t.id == match.homeTeamId,
                          orElse: () => Team.empty()),
                      items: teams.map((team) {
                        return DropdownMenuItem<Team>(
                          value: team,
                          child: Text(team.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        context.read<MatchesformBloc>().add(
                            MatchFormFieldUpdatedEvent(homeTeamId: value?.id));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Team>(
                      decoration: const InputDecoration(labelText: 'Gast Team'),
                      value: teams.firstWhere((t) => t.id == match.guestTeamId,
                          orElse: () => Team.empty()),
                      items: teams.map((team) {
                        return DropdownMenuItem<Team>(
                          value: team,
                          child: Text(team.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        context.read<MatchesformBloc>().add(
                            MatchFormFieldUpdatedEvent(guestTeamId: value?.id));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: homeScoreController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      validator: (value) =>
                          _validateScore(value, state, context, 'home'),
                      maxLength: 2,
                      maxLines: 1,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: "Heimtore",
                        hintText: state.homeScore == null
                            ? ""
                            : state.homeScore.toString(),
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => context.read<MatchesformBloc>().add(
                          MatchFormFieldUpdatedEvent(
                              homeTeamScore: int.tryParse(value))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    ":",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: guestScoreController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      validator: (value) =>
                          _validateScore(value, state, context, 'guest'),
                      maxLength: 2,
                      maxLines: 1,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: "Gasttore",
                        hintText: state.guestScore == null
                            ? ""
                            : state.guestScore.toString(),
                        counterText: "",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) => context.read<MatchesformBloc>().add(
                          MatchFormFieldUpdatedEvent(
                              guestTeamScore: int.tryParse(value))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomDatePickerField(
                      initialDate: state.matchDate,
                      onDateChanged: (DateTime? date) {
                        context
                            .read<MatchesformBloc>()
                            .add(MatchFormFieldUpdatedEvent(matchDate: date));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTimePickerField(
                      initialTime: state.matchTime,
                      onTimeChanged: (TimeOfDay? time) {
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
                decoration: const InputDecoration(labelText: 'Match Tag'),
                value: match.matchDay,
                items: List.generate(8, (index) => index +1).map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(CustomMatch.empty().getStageName(value)),
                  );
                }).toList(),
                onChanged: (value) {
                  context
                      .read<MatchesformBloc>()
                      .add(MatchFormFieldUpdatedEvent(matchDay: value));
                },
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    buttonText: 'Speichern',
                    backgroundColor: themeData.colorScheme.primaryContainer,
                    borderColor: primaryDark,
                    hoverColor: primaryDark,
                    callback: () {
                      if (formKey.currentState!.validate()) {
                        DateTime combinedDateTime = DateTime(
                          state.matchDate!.year,
                          state.matchDate!.month,
                          state.matchDate!.day,
                          state.matchTime!.hour,
                          state.matchTime!.minute,
                        );

                        final CustomMatch updatedMatch = CustomMatch(
                          id: match.id,
                          homeTeamId: state.homeTeamId ?? match.homeTeamId,
                          guestTeamId: state.guestTeamId ?? match.guestTeamId,
                          matchDate: combinedDateTime,
                          matchDay: state.matchDay ?? match.matchDay,
                          homeScore: state.homeScore ?? match.homeScore,
                          guestScore: state.guestScore ?? match.guestScore,
                        );
                        context
                            .read<MatchesformBloc>()
                            .add(MatchFormUpdateEvent(match: updatedMatch));
                      } else {
                        context
                            .read<MatchesformBloc>()
                            .add(MatchFormUpdateEvent(match: null));
                      }
                    },
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  CustomButton(
                    buttonText: 'Abbrechen',
                    backgroundColor: themeData.colorScheme.primaryContainer,
                    borderColor: primaryDark,
                    hoverColor: primaryDark,
                    callback: () {
                      Navigator.of(context).pop();
                    },
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
