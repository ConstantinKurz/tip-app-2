import 'package:flutter/material.dart';
import 'package:flutter_web/constants.dart';
import 'package:flutter_web/presentation/core/buttons/call_to_action.dart';
import 'package:responsive_framework/responsive_framework.dart';

class MultiPlattform extends StatelessWidget {
  const MultiPlattform({super.key});

  @override
  Widget build(BuildContext context) {
    final responsiveValue = ResponsiveWrapper.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: background),
      child: ResponsiveRowColumn(
        columnVerticalDirection: VerticalDirection.up,
        rowCrossAxisAlignment: CrossAxisAlignment.center,
        layout: responsiveValue.isSmallerThan(DESKTOP)
            ? ResponsiveRowColumnType.COLUMN
            : ResponsiveRowColumnType.ROW,
        children: [
          ResponsiveRowColumnItem(
            rowFlex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Multi-Plattform",
                      style: TextStyle(
                          color: Colors.lightBlue,
                          fontFamily: fontFamily,
                          fontSize:
                              responsiveValue.isLargerThan(TABLET) ? 20 : 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(
                    height: 20,
                  ),
                  Text("Reach users on every screen",
                      style: TextStyle(
                          color: textPrimaryLight,
                          fontFamily: fontFamily,
                          fontSize:
                              responsiveValue.isLargerThan(TABLET) ? 60 : 40,
                          height: .9,
                          fontWeight: FontWeight.bold)),
                  Text(
                      "Flutter is an open source framework by Google for building beautiful, natively compiled, multi-platform applications from a single codebase.",
                      style: TextStyle(
                        color: textPrimaryLight,
                        fontFamily: fontFamily,
                        fontSize:
                            responsiveValue.isLargerThan(TABLET) ? 20 : 18,
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  CallToAction(text: "See the target platforms", callBack: (){
                    print("Button pressed");
                  },)
                ],
              ),
            ),
          ),
          ResponsiveRowColumnItem(
              rowFlex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: responsiveValue.equals(TABLET) ? 120 : 50),
                child: Image.asset("assets/images/multi_plattform.png"),
              )),
        ],
      ),
    );
  }
}
