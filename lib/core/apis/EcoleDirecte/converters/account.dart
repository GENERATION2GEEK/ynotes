import 'package:ynotes/core/apis/model.dart';
import 'package:ynotes/core/logic/modelsExporter.dart';

class EcoleDirecteAccountConverter {
  
  static List<SchoolAccount> accounts(Map<String, dynamic> accountData)
  {

  }
  
  static List<Period> periods(Map<String, dynamic> periodsData) {
    List rawPeriods = periodsData['data']['periodes'];
    List<Period> periods = List();
    rawPeriods.forEach((element) {
      periods.add(Period(element["periode"], element["idPeriode"]));
    });
    return periods;
  }
}
