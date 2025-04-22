import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/matches/form/matchesform_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/id.dart';
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

    final themeData = Theme.of(context);

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
        print("CreateMatchForm - Teams: ${teams}");
        print("CreateMatchForm - state.homeTeamId: ${state.homeTeamId}");
        print("CreateMatchForm - state.guestTeamId: ${state.guestTeamId}");
        return Form(
          autovalidateMode: state.showValidationMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          key: formKey,
          child: Column(
            children: [
              DropdownButtonFormField<Team>(
                value: state.homeTeamId == null
                    ? null
                    : teams.firstWhere((t) => t.id == state.homeTeamId?.value,
                        orElse: () => Team.empty()),
                decoration: const InputDecoration(labelText: 'Home Team'),
                items: teams
                    .map((team) =>
                        DropdownMenuItem(value: team, child: Text(team.name)))
                    .toList(),
                validator: (value) => validateTeam(value?.id),
                onChanged: (team) {
                  context.read<MatchesformBloc>().add(
                      MatchFormFieldUpdatedEvent(
                          homeTeamId: UniqueID.fromUniqueString(team!.id)));
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Team>(
                value: state.guestTeamId == null
                    ? null
                    : teams.firstWhere((t) => t.id == state.guestTeamId?.value,
                        orElse: () => Team.empty()),
                decoration: const InputDecoration(labelText: 'Gast Team'),
                validator: (value) => validateTeam(value?.id),
                items: teams
                    .map((team) =>
                        DropdownMenuItem(value: team, child: Text(team.name)))
                    .toList(),
                onChanged: (team) {
                  context.read<MatchesformBloc>().add(
                      MatchFormFieldUpdatedEvent(
                          guestTeamId: UniqueID.fromUniqueString(team!.id)));
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomDatePickerField(
                      initialDate: state.matchDate,
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
                      initialTime: state.matchTime,
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
                items: List.generate(7, (i) => i)
                    .map((day) =>
                        DropdownMenuItem(value: day, child: Text('Tag $day')))
                    .toList(),
                onChanged: (day) {
                  context
                      .read<MatchesformBloc>()
                      .add(MatchFormFieldUpdatedEvent(matchDay: day));
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    buttonText: 'Speichern',
                    borderColor: primaryDark,
                    hoverColor: primaryDark,
                    callback: () {
                      if (formKey.currentState!.validate()) {
                        if (state.matchDate == null ||
                            state.matchTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Bitte Datum und Uhrzeit wählen")));
                          return;
                        }

                        final combinedDateTime = DateTime(
                          state.matchDate!.year,
                          state.matchDate!.month,
                          state.matchDate!.day,
                          state.matchTime!.hour,
                          state.matchTime!.minute,
                        );

                        context.read<MatchesformBloc>().add(
                              CreateMatchEvent(
                                homeTeamId: state.homeTeamId,
                                guestTeamId: state.guestTeamId,
                                matchDate: combinedDateTime,
                                matchDay: state.matchDay,
                              ),
                            );
                      } else {
                        context.read<MatchesformBloc>().add(CreateMatchEvent(
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
                    buttonText: 'Abbrechen',
                    callback: () => Navigator.of(context).pop(),
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

// class CreateMatchForm extends StatefulWidget {
//   final List<Team> teams;

//   const CreateMatchForm({Key? key, required this.teams}) : super(key: key);

//   @override
//   _CreateMatchFormState createState() => _CreateMatchFormState();
// }

// class _CreateMatchFormState extends State<CreateMatchForm> {
//   final GlobalKey<FormState> formKey = GlobalKey<FormState>();

//   late UniqueID _homeTeamId;
//   late UniqueID _guestTeamId;
//   DateTime? _matchDate = DateTime.now();
//   TimeOfDay? _matchTime = TimeOfDay.now();
//   late int _matchDay = 0;

//   // String? validateTeam(String? input) {
//   //   if (input == null) {
//   //     return "Bitte wählen Sie ein Team";
//   //   } else {
//   //     return null;
//   //   }
//   // }

//   // String? validateDate(String? input) {
//   //   if (input == null) {
//   //     return "Bitte wählen Sie ein Datum";
//   //   } else {
//   //     return null;
//   //   }
//   // }

//   // String? validateMatchDay(int? input) {
//   //   if (input == null) {
//   //     return "Bitte wählen Sie einen Match Tag";
//   //   } else {
//   //     return null;
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     String? validateTeam(String? input) {
//       if (input == null) {
//         return "Bitte wählen Sie ein Team";
//       } else {
//         return null;
//       }
//     }

//     String? validateDate(String? input) {
//       if (input == null) {
//         return "Bitte wählen Sie ein Datum";
//       } else {
//         return null;
//       }
//     }

//     String? validateMatchDay(int? input) {
//       if (input == null) {
//         return "Bitte wählen Sie einen Match Tag";
//       } else {
//         return null;
//       }
//     }

//     final themeData = Theme.of(context);
//     return BlocConsumer<MatchesformBloc, MatchesformState>(
//       listenWhen: (p, c) =>
//           p.matchFailureOrSuccessOption != c.matchFailureOrSuccessOption,
//       listener: (context, state) {
//         state.matchFailureOrSuccessOption!.fold(
//             () {},
//             (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold((failure) {
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       backgroundColor: Colors.redAccent,
//                       content: Text(
//                         "Fehler beim Erstellen des Matches",
//                         style: themeData.textTheme.bodyLarge,
//                       )));
//                 }, (_) {
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       backgroundColor: Colors.green,
//                       content: Text(
//                         "Match erfolgreich erstellt!",
//                         style: themeData.textTheme.bodyLarge,
//                       )));
//                 }));
//       },
//       builder: (context, state) {
//         return Form(
//           autovalidateMode: state.showValidationMessages
//               ? AutovalidateMode.always
//               : AutovalidateMode.disabled,
//           key: formKey,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               DropdownButtonFormField<Team>(
//                 decoration: const InputDecoration(labelText: 'Home Team'),
//                 items: widget.teams.map((team) {
//                   return DropdownMenuItem<Team>(
//                     value: team,
//                     child: Text(team.name),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   _homeTeamId = UniqueID.fromUniqueString(value!.id);
//                 },
//                 validator: (value) => validateTeam(value?.id),
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<Team>(
//                 decoration: const InputDecoration(labelText: 'Gast Team'),
//                 items: widget.teams.map((team) {
//                   return DropdownMenuItem<Team>(
//                     value: team,
//                     child: Text(team.name),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   _guestTeamId = UniqueID.fromUniqueString(value!.id);
//                 },
//                 validator: (value) => validateTeam(value?.id),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: CustomDatePickerField(
//                       initialDate: _matchDate,
//                       onDateChanged: (DateTime? date) {
//                         setState(() {
//                           _matchDate = date;
//                         });
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: CustomTimePickerField(
//                       initialTime: _matchTime,
//                       onTimeChanged: (TimeOfDay? time) {
//                         setState(() {
//                           _matchTime = time;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<int>(
//                 decoration: const InputDecoration(labelText: 'Match Tag'),
//                 items: List.generate(7, (index) => index).map((value) {
//                   return DropdownMenuItem<int>(
//                     value: value,
//                     child: Text('Tag $value'),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   _matchDay = value!;
//                 },
//                 validator: (value) => validateMatchDay(value),
//               ),
//               const SizedBox(
//                 height: 16,
//               ),
//               Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                 CustomButton(
//                   buttonText: 'Speichern',
//                   backgroundColor: themeData.colorScheme.primaryContainer,
//                   borderColor: primaryDark,
//                   hoverColor: primaryDark,
//                   callback: () {
//                     if (formKey.currentState!.validate()) {
//                       if (_matchDate == null || _matchTime == null) {
//                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                           backgroundColor: Colors.redAccent,
//                           content: Text(
//                             "Bitte wähle ein Datum und eine Uhrzeit!",
//                             style: themeData.textTheme.bodyLarge,
//                           ),
//                         ));
//                         return;
//                       }

//                       DateTime combinedDateTime = DateTime(
//                         _matchDate!.year,
//                         _matchDate!.month,
//                         _matchDate!.day,
//                         _matchTime!.hour,
//                         _matchTime!.minute,
//                       );

//                       BlocProvider.of<MatchesformBloc>(context).add(
//                         CreateMatchEvent(
//                           homeTeamId: _homeTeamId,
//                           guestTeamId: _guestTeamId,
//                           matchDate: combinedDateTime,
//                           matchDay: _matchDay,
//                         ),
//                       );
//                     } else {
//                       BlocProvider.of<MatchesformBloc>(context).add(
//                           CreateMatchEvent(
//                               homeTeamId: null,
//                               guestTeamId: null,
//                               matchDate: null,
//                               matchDay: null));
//                     }
//                   },
//                 ),
//                 const SizedBox(
//                   width: 8,
//                 ),
//                 CustomButton(
//                   buttonText: 'Abbrechen',
//                   backgroundColor: themeData.colorScheme.primaryContainer,
//                   borderColor: primaryDark,
//                   hoverColor: primaryDark,
//                   callback: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ]),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
