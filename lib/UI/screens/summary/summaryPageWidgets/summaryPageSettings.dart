import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ynotes/utils/themeUtils.dart';

import '../../../../usefulMethods.dart';

class SummaryPageSettings extends StatefulWidget {
  @override
  _SummaryPageSettingsState createState() => _SummaryPageSettingsState();
}

class _SummaryPageSettingsState extends State<SummaryPageSettings> {
  int _slider = 1;
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenSize.size.width / 5 * 0.15),
        color: Theme.of(context).primaryColor,
      ),
      width: screenSize.size.width / 5 * 4.5,
      child: Column(
        children: [
          Container(
              width: screenSize.size.width / 5 * 4.5,
              margin: EdgeInsets.all(screenSize.size.width / 5 * 0.2),
              child: Text(
                "Paramètres des devoirs rapides",
                style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.bold, color: ThemeUtils.textColor()),
                textAlign: TextAlign.left,
              )),
          Container(
            margin: EdgeInsets.only(bottom: (screenSize.size.height / 10 * 8.8) / 10 * 0.2, top: (screenSize.size.height / 10 * 8.8) / 10 * 0.2),
            height: (screenSize.size.height / 10 * 8.8) / 10 * 3,
            child: FutureBuilder(
                future: getIntSetting("summaryQuickHomework"),
                initialData: 1,
                builder: (context, snapshot) {
                  _slider = (snapshot.data == 0) ? 1 : snapshot.data;
                  return ListView(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10),
                    children: <Widget>[
                      CupertinoSlider(
                          value: _slider.toDouble(),
                          min: 1.0,
                          max: 11.0,
                          divisions: 11,
                          onChanged: (double newValue) async {
                            await setIntSetting("summaryQuickHomework", newValue.round());
                            setState(() {
                              _slider = newValue.round();
                            });
                          }),
                      Container(
                        margin: EdgeInsets.only(top: (screenSize.size.height / 10 * 8.8) / 10 * 0.2),
                        child: AutoSizeText(
                          "Devoirs sur :\n" + (_slider.toString() == "11" ? "∞" : _slider.toString()) + " jour" + (_slider > 1 ? "s" : ""),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: "Asap", fontSize: 15, color: ThemeUtils.textColor()),
                        ),
                      )
                    ],
                  );
                }),
          ),
        ],
      ),
    );
  }
}
