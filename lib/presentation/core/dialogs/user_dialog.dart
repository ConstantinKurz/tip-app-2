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


enum UserAction { create, update, delete }
class UserDialog extends StatelessWidget {
  final List<Team>? teams;
  final String dialogText;
  final UserAction userAction;
  final AppUser? user;

  const UserDialog({
    Key? key,
    this.teams,
    required this.dialogText,
    required this.userAction,
    this.user,
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
              switch (userAction) {
                case UserAction.update:
                  return UpdateUserForm(teams: teams!, user: user!,);
                case UserAction.delete:
                  // return DeleteMatchDialog(match: match!);
                case UserAction.create:
                  return const CreateUserForm();
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
