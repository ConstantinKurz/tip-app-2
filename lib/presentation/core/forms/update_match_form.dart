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

  UpdateMatchForm({
    Key? key,
    required this.teams,
    required this.match,
  }) : super(key: key);

  String? _validateScore(String? value) {
    final trimmedValue = value?.trim() ?? '';

    // Ergebnis ist optional. Leeres Feld ist erlaubt.
    if (trimmedValue.isEmpty) {
      return null;
    }

    final intValue = int.tryParse(trimmedValue);

    if (intValue == null || intValue < 0 || intValue > 10) {
      return '[0-10]';
    }

    return null;
  }

  int? _parseOptionalScore(TextEditingController controller) {
    final value = controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  void _submitUpdate(BuildContext context, MatchesformState state) {
    if (formKey.currentState!.validate()) {
      final DateTime safeDate = state.matchDate ?? match.matchDate;
      final TimeOfDay safeTime = state.matchTime ??
          TimeOfDay(
            hour: match.matchDate.hour,
            minute: match.matchDate.minute,
          );

      final DateTime combinedDateTime = DateTime(
        safeDate.year,
        safeDate.month,
        safeDate.day,
        safeTime.hour,
        safeTime.minute,
      );

      final CustomMatch updatedMatch = CustomMatch(
        id: match.id,
        homeTeamId: state.homeTeamId ?? match.homeTeamId,
        guestTeamId: state.guestTeamId ?? match.guestTeamId,
        matchDate: combinedDateTime,
        matchDay: state.matchDay ?? match.matchDay,

        // Wichtig:
        // Direkt aus den Controllern lesen, damit leere Felder wirklich als null gespeichert werden.
        homeScore: _parseOptionalScore(homeScoreController),
        guestScore: _parseOptionalScore(guestScoreController),
      );

      context.read<MatchesformBloc>().add(
            MatchFormUpdateEvent(match: updatedMatch),
          );
    } else {
      context.read<MatchesformBloc>().add(
            MatchFormUpdateEvent(match: null),
          );
    }
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
                    'Fehler beim Aktualisieren des Matches',
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
                    'Match erfolgreich aktualisiert!',
                    style: themeData.textTheme.bodyLarge,
                  ),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        );
      },
      builder: (context, state) {
        final DateTime effectiveDate = state.matchDate ?? match.matchDate;
        final TimeOfDay effectiveTime =
            state.matchTime ?? TimeOfDay.fromDateTime(match.matchDate);

        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return isMobile
                      ? Column(
                          children: [
                            DropdownButtonFormField<Team>(
                              decoration:
                                  const InputDecoration(labelText: 'Home Team'),
                              initialValue: teams.isEmpty
                                  ? null
                                  : teams.any(
                                      (t) =>
                                          t.id ==
                                          (state.homeTeamId ??
                                              match.homeTeamId),
                                    )
                                      ? teams.firstWhere(
                                          (t) =>
                                              t.id ==
                                              (state.homeTeamId ??
                                                  match.homeTeamId),
                                        )
                                      : null,
                              items: teams.map((team) {
                                return DropdownMenuItem<Team>(
                                  value: team,
                                  child: Text(
                                    team.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                context.read<MatchesformBloc>().add(
                                      MatchFormFieldUpdatedEvent(
                                        homeTeamId: value?.id,
                                      ),
                                    );
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Team>(
                              decoration:
                                  const InputDecoration(labelText: 'Gast Team'),
                              initialValue: teams.isEmpty
                                  ? null
                                  : teams.any(
                                      (t) =>
                                          t.id ==
                                          (state.guestTeamId ??
                                              match.guestTeamId),
                                    )
                                      ? teams.firstWhere(
                                          (t) =>
                                              t.id ==
                                              (state.guestTeamId ??
                                                  match.guestTeamId),
                                        )
                                      : null,
                              items: teams.map((team) {
                                return DropdownMenuItem<Team>(
                                  value: team,
                                  child: Text(
                                    team.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                context.read<MatchesformBloc>().add(
                                      MatchFormFieldUpdatedEvent(
                                        guestTeamId: value?.id,
                                      ),
                                    );
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Team>(
                                decoration: const InputDecoration(
                                  labelText: 'Home Team',
                                ),
                                initialValue: teams.isEmpty
                                    ? null
                                    : teams.any(
                                        (t) =>
                                            t.id ==
                                            (state.homeTeamId ??
                                                match.homeTeamId),
                                      )
                                        ? teams.firstWhere(
                                            (t) =>
                                                t.id ==
                                                (state.homeTeamId ??
                                                    match.homeTeamId),
                                          )
                                        : null,
                                items: teams.map((team) {
                                  return DropdownMenuItem<Team>(
                                    value: team,
                                    child: Text(
                                      team.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  context.read<MatchesformBloc>().add(
                                        MatchFormFieldUpdatedEvent(
                                          homeTeamId: value?.id,
                                        ),
                                      );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<Team>(
                                decoration: const InputDecoration(
                                  labelText: 'Gast Team',
                                ),
                                initialValue: teams.isEmpty
                                    ? null
                                    : teams.any(
                                        (t) =>
                                            t.id ==
                                            (state.guestTeamId ??
                                                match.guestTeamId),
                                      )
                                        ? teams.firstWhere(
                                            (t) =>
                                                t.id ==
                                                (state.guestTeamId ??
                                                    match.guestTeamId),
                                          )
                                        : null,
                                items: teams.map((team) {
                                  return DropdownMenuItem<Team>(
                                    value: team,
                                    child: Text(
                                      team.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  context.read<MatchesformBloc>().add(
                                        MatchFormFieldUpdatedEvent(
                                          guestTeamId: value?.id,
                                        ),
                                      );
                                },
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return isMobile
                      ? Column(
                          children: [
                            TextFormField(
                              controller: homeScoreController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              validator: _validateScore,
                              maxLength: 2,
                              maxLines: 1,
                              minLines: 1,
                              decoration: InputDecoration(
                                labelText: 'Heimtore',
                                hintText: state.homeScore == null
                                    ? ''
                                    : state.homeScore.toString(),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                context.read<MatchesformBloc>().add(
                                      MatchFormFieldUpdatedEvent(
                                        homeTeamScore: value.trim().isEmpty
                                            ? null
                                            : int.tryParse(value),
                                      ),
                                    );
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              ':',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: guestScoreController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              validator: _validateScore,
                              maxLength: 2,
                              maxLines: 1,
                              minLines: 1,
                              decoration: InputDecoration(
                                labelText: 'Gasttore',
                                hintText: state.guestScore == null
                                    ? ''
                                    : state.guestScore.toString(),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                context.read<MatchesformBloc>().add(
                                      MatchFormFieldUpdatedEvent(
                                        guestTeamScore: value.trim().isEmpty
                                            ? null
                                            : int.tryParse(value),
                                      ),
                                    );
                              },
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: homeScoreController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                                validator: _validateScore,
                                maxLength: 2,
                                maxLines: 1,
                                minLines: 1,
                                decoration: InputDecoration(
                                  labelText: 'Heimtore',
                                  hintText: state.homeScore == null
                                      ? ''
                                      : state.homeScore.toString(),
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  context.read<MatchesformBloc>().add(
                                        MatchFormFieldUpdatedEvent(
                                          homeTeamScore: value.trim().isEmpty
                                              ? null
                                              : int.tryParse(value),
                                        ),
                                      );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              ':',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: guestScoreController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                                validator: _validateScore,
                                maxLength: 2,
                                maxLines: 1,
                                minLines: 1,
                                decoration: InputDecoration(
                                  labelText: 'Gasttore',
                                  hintText: state.guestScore == null
                                      ? ''
                                      : state.guestScore.toString(),
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onChanged: (value) {
                                  context.read<MatchesformBloc>().add(
                                        MatchFormFieldUpdatedEvent(
                                          guestTeamScore: value.trim().isEmpty
                                              ? null
                                              : int.tryParse(value),
                                        ),
                                      );
                                },
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return isMobile
                      ? Column(
                          children: [
                            CustomDatePickerField(
                              initialDate: effectiveDate,
                              onDateChanged: (DateTime? date) {
                                context.read<MatchesformBloc>().add(
                                      MatchFormFieldUpdatedEvent(
                                        matchDate: date,
                                      ),
                                    );
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTimePickerField(
                              initialTime: effectiveTime,
                              onTimeChanged: (TimeOfDay? time) {
                                context.read<MatchesformBloc>().add(
                                      MatchFormFieldUpdatedEvent(
                                        matchTime: time,
                                      ),
                                    );
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: CustomDatePickerField(
                                initialDate: effectiveDate,
                                onDateChanged: (DateTime? date) {
                                  context.read<MatchesformBloc>().add(
                                        MatchFormFieldUpdatedEvent(
                                          matchDate: date,
                                        ),
                                      );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTimePickerField(
                                initialTime: effectiveTime,
                                onTimeChanged: (TimeOfDay? time) {
                                  context.read<MatchesformBloc>().add(
                                        MatchFormFieldUpdatedEvent(
                                          matchTime: time,
                                        ),
                                      );
                                },
                              ),
                            ),
                          ],
                        );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Match Tag'),
                initialValue: match.matchDay,
                items: List.generate(8, (index) => index + 1).map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  context.read<MatchesformBloc>().add(
                        MatchFormFieldUpdatedEvent(matchDay: value),
                      );
                },
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return isMobile
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                buttonText: 'Speichern',
                                backgroundColor:
                                    themeData.colorScheme.primaryContainer,
                                borderColor: primaryDark,
                                hoverColor: primaryDark,
                                callback: () => _submitUpdate(context, state),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                buttonText: 'Abbrechen',
                                backgroundColor:
                                    themeData.colorScheme.primaryContainer,
                                borderColor: primaryDark,
                                hoverColor: primaryDark,
                                callback: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: CustomButton(
                                buttonText: 'Speichern',
                                backgroundColor:
                                    themeData.colorScheme.primaryContainer,
                                borderColor: primaryDark,
                                hoverColor: primaryDark,
                                callback: () => _submitUpdate(context, state),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomButton(
                                buttonText: 'Abbrechen',
                                backgroundColor:
                                    themeData.colorScheme.primaryContainer,
                                borderColor: primaryDark,
                                hoverColor: primaryDark,
                                callback: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
