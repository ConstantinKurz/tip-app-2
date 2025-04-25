import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_date_picker.dart';
import 'package:flutter_web/presentation/core/date_picker/custom_time_picker.dart';

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

  String? _homeTeamId;
  String? _guestTeamId;
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

  String? _validateScore(String? value, String scoreType) {
    if (value == null || value.isEmpty) {
      if ((_homeScoreController.text.isNotEmpty && scoreType == 'guest') ||
          (_guestScoreController.text.isNotEmpty && scoreType == 'home')) {
        return '[0-10]';
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Team>(
                    decoration: const InputDecoration(labelText: 'Home Team'),
                    value: widget.teams.firstWhere(
                        (team) => team.id == widget.match.homeTeamId),
                    items: widget.teams.map((team) {
                      return DropdownMenuItem<Team>(
                        value: team,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _homeTeamId = value?.id;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Team>(
                    decoration: const InputDecoration(labelText: 'Gast Team'),
                    value: widget.teams.firstWhere(
                        (team) => team.id == widget.match.guestTeamId),
                    items: widget.teams.map((team) {
                      return DropdownMenuItem<Team>(
                        value: team,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _guestTeamId = value?.id;
                      });
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
                    controller: _homeScoreController,
                    style: const TextStyle(color: Colors.white),
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
                    style: const TextStyle(color: Colors.white),
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
                  child: CustomDatePickerField(
                    initialDate: _matchDate,
                    onDateChanged: (DateTime? date) {
                      setState(() {
                        _matchDate = date;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTimePickerField(
                    initialTime: _matchTime,
                    onTimeChanged: (TimeOfDay? time) {
                      setState(() {
                        _matchTime = time;
                      });
                    },
                    // hourValidator: _validateHour,
                    // minuteValidator: _validateMinute,
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
