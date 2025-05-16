// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'tipform_bloc.dart';

class TipFormState {
  final Tip tip;
  final bool showErrorMessages;
  final bool isSaving;
  final bool isEditing;
  final Option<Either<TipFailure, Unit>> failureOrSuccessOption;
  TipFormState({
    required this.tip,
    required this.showErrorMessages,
    required this.isSaving,
    required this.isEditing,
    required this.failureOrSuccessOption,
  });

  factory TipFormState.initial() => TipFormState(
      tip: Tip.empty(UniqueID()),
      showErrorMessages: false,
      isSaving: false,
      isEditing: false,
      failureOrSuccessOption: none());

  TipFormState copyWith({
    Tip? tip,
    bool? showErrorMessages,
    bool? isSaving,
    bool? isEditing,
    Option<Either<TipFailure, Unit>>? failureOrSuccessOption,
  }) {
    return TipFormState(
      tip: tip ?? this.tip,
      showErrorMessages: showErrorMessages ?? this.showErrorMessages,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      failureOrSuccessOption:
          failureOrSuccessOption ?? this.failureOrSuccessOption,
    );
  }
}
