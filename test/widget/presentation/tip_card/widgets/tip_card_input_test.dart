import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_web/application/tips/form/tipform_bloc.dart';
import 'package:flutter_web/domain/entities/tip.dart';
import 'package:flutter_web/presentation/tip_card/widgets/tip_card_input.dart';

class MockTipFormBloc extends Mock implements TipFormBloc {}
class FakeTipFormState extends Fake implements TipFormState {}

void main() {
  late MockTipFormBloc mockTipFormBloc;

  setUpAll(() {
    registerFallbackValue(FakeTipFormState());
  });

  setUp(() {
    mockTipFormBloc = MockTipFormBloc();
    when(() => mockTipFormBloc.stream).thenAnswer((_) => Stream.value(TipFormInitialState()));
  });

  group('TipCardInput Widget', () {
    testWidgets('renders TipCardInput and text fields', (tester) async {
      when(() => mockTipFormBloc.state).thenReturn(TipFormInitialState());

      await tester.pumpWidget(
        BlocProvider<TipFormBloc>.value(
          value: mockTipFormBloc,
          child: MaterialApp(
            home: Scaffold(
              body: TipCardTippingInput(
                state: TipFormInitialState(),
                userId: 'testUser',
                matchId: 'testMatch',
                homeController: TextEditingController(text: '1'),
                guestController: TextEditingController(text: '2'),
                tip: Tip.empty('testUser'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TipCardTippingInput), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}
