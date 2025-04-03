import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/match.dart';

class UpdateMatchForm extends StatefulWidget {
  final List<Team> teams;
  final CustomMatch match;

  const UpdateMatchForm({Key? key, required this.teams, required this.match})
      : super(key: key);

  @override
  _UpdateMatchFormState createState() => _UpdateMatchFormState();
}

class _UpdateMatchFormState extends State<UpdateMatchForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  UniqueID? _homeTeamId;
  UniqueID? _guestTeamId;
  DateTime? _matchDate;
  TimeOfDay? _matchTime;
  int _matchDay = 0;

  @override
  void initState() {
    super.initState();
    _homeTeamId = widget.match.homeTeamId;
    _guestTeamId = widget.match.guestTeamId;
    _matchDate = widget.match.matchDate;
    _matchTime = TimeOfDay.fromDateTime(widget.match.matchDate);
    _matchDay = widget.match.matchDay;
  }

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
          print("listen!!");
          state.matchFailureOrSuccessOption!.fold(
              () {},
              (eitherFailureOrSuccess) =>
                  eitherFailureOrSuccess.fold((failure) {
                    print("error");
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
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Team>(
                  decoration: const InputDecoration(labelText: 'Home Team'),
                  value: widget.teams.firstWhere(
                      (team) => team.id == widget.match.homeTeamId.value),
                  items: widget.teams.map((team) {
                    return DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _homeTeamId = UniqueID.fromUniqueString(value!.id);
                    });
                  },
                  validator: (value) => validateTeam(value?.id),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Team>(
                  decoration: const InputDecoration(labelText: 'Gast Team'),
                  value: widget.teams.firstWhere(
                      (team) => team.id == widget.match.guestTeamId.value),
                  items: widget.teams.map((team) {
                    return DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _guestTeamId = UniqueID.fromUniqueString(value!.id);
                    });
                  },
                  validator: (value) => validateTeam(value?.id),
                ),
                const SizedBox(height: 16),
                Row(
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
                          child: Text(_matchDate != null
                              ? '${_matchDate!.day.toString().padLeft(2, '0')}.${_matchDate!.month.toString().padLeft(2, '0')}.${_matchDate!.year}'
                              : 'Kein Datum ausgewählt'),
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
                          child: Text(_matchTime != null
                              ? '${_matchTime!.hour.toString().padLeft(2, '0')}:${_matchTime!.minute.toString().padLeft(2, '0')}'
                              : 'Keine Uhrzeit ausgewählt'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Match Tag'),
                  value: _matchDay,
                  items: List.generate(7, (index) => index).map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('Tag $value'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _matchDay = value!;
                    });
                  },
                  validator: (value) => validateMatchDay(value),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                    child: const Text('Speichern',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        DateTime combinedDateTime = DateTime(
                          _matchDate!.year,
                          _matchDate!.month,
                          _matchDate!.day,
                          _matchTime!.hour,
                          _matchTime!.minute,
                        );
                        print('Matchday wird übergeben: $_matchDay');
                        final CustomMatch updatedMatch = CustomMatch(
                            id: widget.match.id,
                            homeTeamId: _homeTeamId!,
                            guestTeamId: _guestTeamId!,
                            matchDate: combinedDateTime,
                            matchDay: _matchDay,
                            homeScore: widget.match.homeScore,
                            guestScore: widget.match.homeScore);
                        BlocProvider.of<MatchesformBloc>(context).add(
                          MatchFormUpdateEvent(match: updatedMatch),
                        );
                      }
                      Navigator.of(context).pop();
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
        });
  }
}
