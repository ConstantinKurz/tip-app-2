import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/id.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';

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

  final TextEditingController _homeScoreController = TextEditingController();
  final TextEditingController _guestScoreController = TextEditingController();

  UniqueID? _homeTeamId;
  UniqueID? _guestTeamId;
  DateTime? _matchDate;
  TimeOfDay? _matchTime;
  int _matchDay = 0;
  late int? _homeScore;
  late int? _guestScore;

  @override
  void initState() {
    super.initState();
    _homeTeamId = widget.match.homeTeamId;
    _guestTeamId = widget.match.guestTeamId;
    _matchDate = widget.match.matchDate;
    _matchTime = TimeOfDay.fromDateTime(widget.match.matchDate);
    _matchDay = widget.match.matchDay;
    _homeScore = widget.match.homeScore;
    _guestScore = widget.match.guestScore;

    _homeScoreController.text = _homeScore?.toString() ?? '';
    _guestScoreController.text = _guestScore?.toString() ?? '';
  }

  @override
  void dispose() {
    _guestScoreController.dispose();
    _homeScoreController.dispose();
    super.dispose();
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

  String? _validateScore(String? value, String scoreType) {
    if (value == null || value.isEmpty) {
      if ((_homeScoreController.text.isNotEmpty && scoreType == 'guest') ||
          (_guestScoreController.text.isNotEmpty && scoreType == 'home')) {
        return ' 0 - 11';
      }
      return null;
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > 11) {
      return 'Bitte einen Wert zwischen 0 und 11 eingeben';
    }
    if (scoreType == 'home') {
      _homeScore = intValue;
    } else if (scoreType == 'guest') {
      _guestScore = intValue;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocConsumer<MatchesformBloc, MatchesformState>(
        listenWhen: (previous, current) {
      print('Previous State: $previous');
      print('Current State: $current');
      return previous.isSubmitting != current.isSubmitting;
    }, listener: (context, state) {
      print("listen!!");
      state.matchFailureOrSuccessOption!.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
                print("error");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.redAccent,
                    content: Text(
                      "Fehler beim Erstellen des Matches",
                      style: themeData.textTheme.bodyLarge,
                    )));
              }, (_) {
                print("success");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                      "Match erfolgreich aktualisiert!",
                      style: themeData.textTheme.bodyLarge,
                    )));
                // close form when update was successful
                Navigator.of(context).pop();
              }));
    }, builder: (context, state) {
      return Form(
        autovalidateMode: state.showValidationMessages
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        key: formKey,
        child: Column(
          mainAxisSize:
              MainAxisSize.max, // Wichtig: mainAxisSize auf max setzen
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Team>(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Team>(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _homeScoreController,
                    cursorColor: Colors.white,
                    validator: (value) => _validateScore(value, 'home'),
                    maxLength: 2,
                    maxLines: 1,
                    minLines: 1,
                    decoration: InputDecoration(
                        labelText: "Heimtore",
                        hintText: _homeScore?.toString() ?? '',
                        counterText: "",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(":"),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _guestScoreController,
                    cursorColor: Colors.white,
                    validator: (value) => _validateScore(value, 'guest'),
                    maxLength: 2,
                    maxLines: 1,
                    minLines: 1,
                    decoration: InputDecoration(
                        labelText: "Gasttore",
                        hintText: _guestScore?.toString() ?? '',
                        counterText: "",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8))),
                  ),
                ),
              ],
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
            const SizedBox(
              height: 16,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                        _matchDate!.year,
                        _matchDate!.month,
                        _matchDate!.day,
                        _matchTime!.hour,
                        _matchTime!.minute,
                      );
                      final CustomMatch updatedMatch = CustomMatch(
                          id: widget.match.id,
                          homeTeamId: _homeTeamId!,
                          guestTeamId: _guestTeamId!,
                          matchDate: combinedDateTime,
                          matchDay: _matchDay,
                          homeScore: _homeScore,
                          guestScore: _guestScore);
                      BlocProvider.of<MatchesformBloc>(context).add(
                        MatchFormUpdateEvent(match: updatedMatch),
                      );
                    } else {
                      BlocProvider.of<MatchesformBloc>(context)
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
    });
  }
}
