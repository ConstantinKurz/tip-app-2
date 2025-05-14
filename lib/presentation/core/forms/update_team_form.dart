import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/application/teams/form/teamsform_bloc.dart';
import 'package:flutter_web/presentation/core/buttons/custom_button.dart';
import 'package:flutter_web/presentation/core/buttons/star_icon_button.dart';

class UpdateTeamForm extends StatelessWidget {
  final Team team;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController flagCodeController = TextEditingController();
  final TextEditingController winPointsController = TextEditingController();

  UpdateTeamForm({Key? key, required this.team}) : super(key: key);

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dieses Feld darf nicht leer sein.';
    }
    return null;
  }

  String? _validateWinPoints(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte geben Sie die Gewinnpunkte ein.';
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0) {
      return 'Bitte geben Sie eine gültige nicht-negative Zahl ein.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    nameController.text = team.name;
    flagCodeController.text = team.flagCode;
    winPointsController.text = team.winPoints.toString();

    return BlocConsumer<TeamsformBloc, TeamsformState>(
      listenWhen: (previous, current) =>
          previous.teamFailureOrSuccessOption !=
          current.teamFailureOrSuccessOption,
      listener: (context, state) {
        state.teamFailureOrSuccessOption!.fold(
          () {},
          (eitherFailureOrSuccess) => eitherFailureOrSuccess.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    "Fehler beim aktualiseren des Teams",
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              );
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    "Team erfolgreich aktualisiert!",
                    style: themeData.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              );
              Navigator.of(context).pop();
            },
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
              TextFormField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Team Name',
                  hintText: team.name,
                ),
                validator: _validateNotEmpty,
                onChanged: (value) => context
                    .read<TeamsformBloc>()
                    .add(TeamFormFieldUpdatedEvent(name: value)),
              ),
              TextFormField(
                controller: flagCodeController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                    labelText: 'Flag Code', hintText: team.flagCode),
                validator: _validateNotEmpty,
                onChanged: (value) => context
                    .read<TeamsformBloc>()
                    .add(TeamFormFieldUpdatedEvent(flagCode: value)),
              ),
              TextFormField(
                controller: winPointsController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                    labelText: 'Punkte', hintText: team.winPoints.toString()),
                keyboardType: TextInputType.number,
                validator: _validateWinPoints,
                onChanged: (value) => context.read<TeamsformBloc>().add(
                    TeamFormFieldUpdatedEvent(winPoints: int.tryParse(value))),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  StarIconButton(
                    isStar: state.champion ?? team.champion,
                    onTap: () {
                      final newValue = !(state.champion ?? team.champion);
                      context.read<TeamsformBloc>().add(
                            TeamFormFieldUpdatedEvent(champion: newValue),
                          );
                    },
                    size: 30.0,
                    tooltipMessage: (state.champion ?? team.champion)
                        ? 'Ist Champion'
                        : 'Ist kein Champion',
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  const Text('Champion', style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
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
                        final Team updatedTeam = Team(
                          id: state.id ?? team.id,
                          name: state.name ?? team.name,
                          flagCode: state.flagCode ?? team.flagCode,
                          winPoints: state.winPoints ?? team.winPoints,
                          champion: state.champion ?? team.champion,
                        );
                        context
                            .read<TeamsformBloc>()
                            .add(TeamFormUpdateEvent(team: updatedTeam));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
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
