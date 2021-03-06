import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ynotes/shared_preferences.dart';
import 'package:ynotes/UI/components/dialogs.dart';
import 'package:ynotes/UI/components/modalBottomSheets/keyValues.dart';

import '../../../classes.dart';

///Bottom windows with some infos on the discipline and the possibility to change the discipline color
void disciplineModalBottomSheet(context, Discipline discipline, Function callback, var widget) {
  Color colorGroup;
  if (widget.disciplinevar == null) {
    colorGroup = Colors.blueAccent;
  } else {
    if (widget.disciplinevar.color != null) {
      colorGroup = Color(widget.disciplinevar.color);
    }
  }
  MediaQueryData screenSize = MediaQuery.of(context);
  showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      backgroundColor: Theme.of(context).primaryColorDark,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Wrap(
          alignment: WrapAlignment.center,
          children: [
            Column(
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenSize.size.width * 0.8),
                  child: FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(top: screenSize.size.height / 10 * 0.05),
                          decoration:
                              BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(25)), color: colorGroup),
                          padding: EdgeInsets.all(5),
                          child: FittedBox(
                            child: Text(
                              discipline.disciplineName,
                              style: TextStyle(fontFamily: "Asap", fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Container(
                            height: (screenSize.size.height / 3) / 6,
                            width: (screenSize.size.height / 3) / 6,
                            padding: EdgeInsets.all(5),
                            child: Material(
                                borderRadius: BorderRadius.circular(80),
                                color: Colors.grey.withOpacity(0.5),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(80),
                                  radius: 25,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    Color color = await CustomDialogs.showColorPicker(context, Color(discipline.color));

                                    if (color != null) {
                                      String test = color.toString();
                                      String finalColor = "#" + test.toString().substring(10, test.length - 1);
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString(discipline.disciplineCode, finalColor);
                                      discipline.setcolor = color;
                                      //Call set state
                                      callback();
                                    }
                                  },
                                  splashColor: Colors.grey,
                                  highlightColor: Colors.grey,
                                  child: Container(
                                    child: Icon(
                                      Icons.color_lens,
                                      color: Colors.black26,
                                    ),
                                  ),
                                )))
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: (screenSize.size.height / 10 * 0.2)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildKeyValuesInfo(context, "Votre moyenne", [discipline.average]),
                      SizedBox(
                        height: (screenSize.size.height / 3) / 25,
                      ),
                      buildKeyValuesInfo(context, "Moyenne de la classe", [discipline.classAverage]),
                      SizedBox(
                        height: (screenSize.size.height / 3) / 25,
                      ),
                      buildKeyValuesInfo(context, "Moyenne la plus élevée", [discipline.maxClassAverage]),
                      if (discipline.minClassAverage != null)
                        SizedBox(
                          height: (screenSize.size.height / 3) / 25,
                        ),
                      if (discipline.minClassAverage != null)
                        buildKeyValuesInfo(context, "Moyenne la plus basse", [discipline.minClassAverage]),
                      if (discipline.disciplineRank != null)
                      SizedBox(
                        height: (screenSize.size.height / 3) / 25,
                      ),
                      if (discipline.disciplineRank != null)
                      buildKeyValuesInfo(context, "Rang",
                          [discipline.disciplineRank.toString() + "/" + discipline.classNumber.toString()]),
                      SizedBox(
                        height: (screenSize.size.height / 3) / 25,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        );
      });
}
