import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web/application/auth/form/authform_bloc.dart';
import 'package:flutter_web/domain/entities/match.dart';
import 'package:flutter_web/domain/entities/team.dart';
import 'package:flutter_web/domain/entities/user.dart';
import 'package:flutter_web/injections.dart';
import 'package:flutter_web/presentation/core/dialogs/match_delete_dialog.dart';
import 'package:flutter_web/presentation/core/forms/create_user_form.dart';
import 'package:flutter_web/presentation/core/forms/update_user_form.dart';


enum TeamAction { create, update, delete }
class TeamDialog extends StatelessWidget {
  final String dialogText;
  final TeamAction teamAction;

  const TeamDialog({
    Key? key,
    required this.dialogText,
    required this.teamAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider<AuthformBloc>(
      create: (context) => sl<AuthformBloc>(),
      child: AlertDialog(
        title: Text(dialogText),
        content: SizedBox(
          width: screenWidth * 0.3,
          height: screenHeight * 0.6,
          child: Builder(
            builder: (context) {
              switch (teamAction) {
                // case teamAction.update:
                //   return UpdateUserForm();
                // case teamAction.delete:
                //   // return DeleteMatchDialog(match: match!);
                // case teamAction.create:
                //   return const CreateUserForm();
                default:
                  return const CreateUserForm();
              }
            },
          ),
        ),
      ),
    );
  }
}
