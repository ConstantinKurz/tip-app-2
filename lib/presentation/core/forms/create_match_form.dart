import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/team.dart';

class CreateMatchForm extends StatefulWidget {
  final List<Team> teams;

  const CreateMatchForm({Key? key, required this.teams}) : super(key: key);

  @override
  _CreateMatchFormState createState() => _CreateMatchFormState();
}

class _CreateMatchFormState extends State<CreateMatchForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late UniqueID _homeTeamId;
  late UniqueID _guestTeamId;
  DateTime? _matchDate = DateTime.now();
  TimeOfDay? _matchTime = TimeOfDay.now();
  late int _matchDay;

  String? validateTeam(String? input) {
    if (input == null) {
      return "Bitte wählen Sie ein Team";
    } else {
      return null;
    }
  }

  String? validateDate(String? input) {
    if (input == null) {
      return "Bitte wählen Sie ein Datum";
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

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<MatchesformBloc, MatchesformState>(
      listenWhen: (p, c) =>
          p.matchFailureOrSuccessOption != c.matchFailureOrSuccessOption,
      listener: (context, state) {
        state.matchFailureOrSuccessOption!.fold(
            () {},
            (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.redAccent,
                      content: Text(
                        "Fehler beim Erstellen des Matches",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }, (_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(
                        "Match erfolgreich erstellt!",
                        style: themeData.textTheme.bodyLarge,
                      )));
                }));
      },
      builder: (context, state) {
        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Team>(
                decoration: const InputDecoration(labelText: 'Home Team'),
                items: widget.teams.map((team) {
                  return DropdownMenuItem<Team>(
                    value: team,
                    child: Text(team.name),
                  );
                }).toList(),
                onChanged: (value) {
                  _homeTeamId = UniqueID.fromUniqueString(value!.id);
                },
                validator: (value) => validateTeam(value?.id),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Team>(
                decoration: const InputDecoration(labelText: 'Gast Team'),
                items: widget.teams.map((team) {
                  return DropdownMenuItem<Team>(
                    value: team,
                    child: Text(team.name),
                  );
                }).toList(),
                onChanged: (value) {
                  _guestTeamId = UniqueID.fromUniqueString(value!.id);
                },
                validator: (value) => validateTeam(value?.id),
              ),
              const SizedBox(height: 16),
              Row(
                // Wrap with Row
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _matchDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _matchDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Datum',
                          hintText: 'Datum auswählen',
                        ),
                        child: Text(_matchDate.toString()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _matchTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _matchTime = pickedTime;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Uhrzeit',
                          hintText: 'Uhrzeit auswählen',
                        ),
                        child: Text(_matchTime.toString()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Match Tag'),
                items: List.generate(7, (index) => index).map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('Tag $value'),
                  );
                }).toList(),
                onChanged: (value) {
                  _matchDay = value!;
                },
                validator: (value) => validateMatchDay(value),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                  child: const Text('Erstellen',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (_matchDate == null || _matchTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            "Bitte wähle ein Datum und eine Uhrzeit!",
                            style: themeData.textTheme.bodyLarge,
                          ),
                        ));
                        return;
                      }

                      DateTime combinedDateTime = DateTime(
                        _matchDate!.year,
                        _matchDate!.month,
                        _matchDate!.day,
                        _matchTime!.hour,
                        _matchTime!.minute,
                      );

                      BlocProvider.of<MatchesformBloc>(context).add(
                        CreateMatchEvent(
                          homeTeamId: _homeTeamId,
                          guestTeamId: _guestTeamId,
                          matchDate:
                              combinedDateTime, // Sicher, da wir es validiert haben
                          matchDay: _matchDay,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            "Ungültige Eingabe",
                            style: themeData.textTheme.bodyLarge,
                          )));
                    }
                  },
                ),
                TextButton(
                    child: const Text('Abbrechen',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })
              ]),
            ],
          ),
        );
      },
    );
  }
}
