// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'teamsform_bloc.dart';

class TeamsformState {
  final String? id;
  final String? name;
  final String? flagCode;
  final int? winPoints;
  final bool? champion;
  final bool isSubmitting;
  final bool showValidationMessages;
  final Option<Either<TeamFailure, Unit>>? teamFailureOrSuccessOption;

  TeamsformState(
      {this.id,
      this.name,
      this.winPoints,
      this.flagCode,
      this.champion,
      required this.isSubmitting,
      required this.showValidationMessages,
      this.teamFailureOrSuccessOption});

  TeamsformState copyWith({
    String? id,
    String? name,
    int? winPoints,
    String? flagCode,
    bool? champion,
    bool? isSubmitting,
    bool? showValidationMessages,
    Option<Either<TeamFailure, Unit>>? teamFailureOrSuccessOption,
  }) {
    return TeamsformState(
      id: id ?? this.id,
      name: name ?? this.name,
      winPoints: winPoints ?? this.winPoints,
      flagCode: flagCode ?? this.flagCode,
      champion: champion ?? this.champion,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showValidationMessages:
          showValidationMessages ?? this.showValidationMessages,
      teamFailureOrSuccessOption:
          teamFailureOrSuccessOption ?? this.teamFailureOrSuccessOption,
    );
  }
}

final class TeamsformInitialState extends TeamsformState {
  TeamsformInitialState()
      : super(
            id: null,
            name: null,
            winPoints: null,
            champion: null,
            flagCode: null,
            isSubmitting: false,
            showValidationMessages: false,
            teamFailureOrSuccessOption: none());
}
