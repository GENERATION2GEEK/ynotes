import 'dart:async';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dnd/flutter_dnd.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart';
import 'package:ynotes/classes.dart';
import 'package:ynotes/main.dart';
import 'package:ynotes/offline/offline.dart';
import 'package:ynotes/shared_preferences.dart';
import 'package:ynotes/usefulMethods.dart';

import 'UI/screens/agenda/agendaPageWidgets/agenda.dart';
import 'UI/screens/settings/sub_pages/logsPage.dart';
import 'apis/utils.dart';
import 'background.dart';
import 'utils/fileUtils.dart';
import 'utils/themeUtils.dart';

///The notifications class
class AppNotification {
  static Future<void> scheduleAgendaReminders(AgendaEvent event) async {
    try {
      AwesomeNotifications().initialize(null, [
        NotificationChannel(
            icon: 'resource://drawable/calendar',
            channelKey: 'alarm',
            channelName: 'Alarmes',
            channelDescription: 'Alarmes',
            defaultColor: ThemeUtils.spaceColor(),
            ledColor: Colors.white),
      ]);

      //Unschedule existing
      if (event.alarm == alarmType.none) {
      } else {
        //delay between task start and task end
        Duration delay = Duration();
        if (event.alarm == alarmType.exactly) {
          delay = Duration.zero;
        }
        if (event.alarm == alarmType.fiveMinutes) {
          delay = Duration(minutes: 5);
        }
        if (event.alarm == alarmType.fifteenMinutes) {
          delay = Duration(minutes: 15);
        }
        if (event.alarm == alarmType.thirtyMinutes) {
          delay = Duration(minutes: 30);
        }
        if (event.alarm == alarmType.oneDay) {
          delay = Duration(days: 1);
        }
        String time = DateFormat("HH:mm").format(event.start);
        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: event.id.hashCode,
                channelKey: 'alarm',
                title: (event.name ?? "(Sans titre)") + " à $time",
                body: event.description,
                notificationLayout: parse(event.description).documentElement.text.length < 49
                    ? NotificationLayout.Default
                    : NotificationLayout.BigText),
            schedule: NotificationSchedule(preciseSchedules: [event.start.subtract(delay).toUtc()]));
        print("Scheduled an alarm" + event.start.subtract(delay).toString() + " " + event.id.hashCode.toString());
      }
    } catch (e) {
      print(e);
    }
  }
  ///Shows a debug notification, useful for development purposes
  static showDebugNotification() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
          channelKey: 'debug',
          defaultPrivacy: NotificationPrivacy.Public,
          channelShowBadge: true,
          channelName: 'Notification de déboguage',
          importance: NotificationImportance.High,
          channelDescription: "Notification à usage de développement",
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.white)
    ]);

    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 0,
      channelKey: 'debug',
      title: 'Notification de test',
      notificationLayout: NotificationLayout.BigText,
      body: "Si vous voyez cette notification, alors yNotes est bien autorisé à vous envoyer des notifications.",
    ));
  }

  static showNewMailNotification(Mail mail, String content) async {
    await AwesomeNotifications().initialize('resource://drawable/mail', [
      NotificationChannel(
          channelKey: 'newmail',
          defaultPrivacy: NotificationPrivacy.Public,
          channelShowBadge: true,
          channelName: 'Nouveau mail',
          importance: NotificationImportance.High,
          groupKey: "mailsGroup",
          channelDescription: "Nouveau mail",
          ledColor: Colors.white)
    ]);

    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: int.parse(mail.id),
          notificationLayout: parse(content).documentElement.text.length < 49 ? null : NotificationLayout.BigText,
          channelKey: 'newmail',
          title: 'Nouveau mail de ${mail.from["name"]}',
          summary: 'Nouveau mail de ${mail.from["name"]}',
          body: content,
          payload: {
            "name": mail.from["prenom"],
            "surname": mail.from["nom"],
            "id": mail.id.toString(),
            "isTeacher": (mail.from["type"] == "P").toString(),
            "subject": mail.subject
          }),
      actionButtons: [
        NotificationActionButton(
            key: "REPLY", label: "Répondre", autoCancel: true, buttonType: ActionButtonType.Default),
      ],
    );
  }

  static showNewGradeNotification() async {
    await AwesomeNotifications().initialize('resource://drawable/newgradeicon', [
      NotificationChannel(
          channelKey: 'newgrade',
          defaultPrivacy: NotificationPrivacy.Public,
          channelName: 'Nouvelle note',
          importance: NotificationImportance.High,
          channelDescription: "Nouvelles notes",
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.white)
    ]);

    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 0,
          channelKey: 'newgrade',
          title: 'Vous avez une ou plusieurs nouvelles notes !',
          summary: "Tapez pour consulter",
          showWhen: false),
    );
  }

  static Future<void> scheduleReminders(AgendaEvent event) async {
    await AwesomeNotifications().initialize('resource://drawable/clock', [
      NotificationChannel(
          channelKey: 'reminder',
          defaultPrivacy: NotificationPrivacy.Public,
          channelShowBadge: true,
          channelName: 'Rappel pour un évènement',
          importance: NotificationImportance.High,
          defaultColor: ThemeUtils.spaceColor(),
          ledColor: Colors.white)
    ]);
    List<AgendaReminder> reminders = await offline.reminders.getReminders(event.lesson.id);
    await Future.forEach(reminders, (AgendaReminder rmd) async {
      //Unschedule existing
      if (rmd.alarm == alarmType.none) {
        await cancelNotification(event.id.hashCode);
      } else {
        //delay between task start and task end
        Duration delay = Duration();
        if (rmd.alarm == alarmType.exactly) {
          delay = Duration.zero;
        }
        if (rmd.alarm == alarmType.fiveMinutes) {
          delay = Duration(minutes: 5);
        }
        if (rmd.alarm == alarmType.fifteenMinutes) {
          delay = Duration(minutes: 15);
        }
        if (rmd.alarm == alarmType.thirtyMinutes) {
          delay = Duration(minutes: 30);
        }
        if (rmd.alarm == alarmType.oneDay) {
          delay = Duration(days: 1);
        }
        String text = "Rappel relié à l'évènement ${event.name} : \n <b>${rmd.name}</b> ${rmd.description}";
        print(event.start.subtract(delay));
        print(text);

        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: rmd.id.hashCode,
                channelKey: 'reminder',
                title: "Rappel d'évènement",
                body: text,
                notificationLayout:
                    event.description.length < 49 ? NotificationLayout.Default : NotificationLayout.BigText),
            schedule: NotificationSchedule(preciseSchedules: [event.start.subtract(delay).toUtc()]));
      }
    });
  }

  static Future<void> showOngoingNotification(Lesson lesson) async {
    var id = 333;

    if (await getSetting("agendaOnGoingNotification")) {
      await AwesomeNotifications().initialize('resource://drawable/tfiche', [
        NotificationChannel(
            channelKey: 'persisnotif',
            defaultPrivacy: NotificationPrivacy.Public,
            channelName: 'Rappel de cours constant',
            importance: NotificationImportance.Low,
            channelDescription: "Notification persistante de cours",
            defaultColor: ThemeUtils.spaceColor(),
            ledColor: Colors.white,
            onlyAlertOnce: true)
      ]);

      String defaultSentence = "";
      if (lesson != null) {
        defaultSentence = 'Vous êtes en <b>${lesson.discipline}</b> dans la salle <b>${lesson.room}</b>';
        if (lesson.room == null || lesson.room == "") {
          defaultSentence = "Vous êtes en ${lesson.discipline}";
        }
      } else {
        defaultSentence = "Vous êtes en pause";
      }

      var sentence = defaultSentence;
      try {
        if (lesson.canceled) {
          sentence = "Votre cours a été annulé.";
        }
      } catch (e) {}
      try {
        print(parse(sentence).documentElement.text.length);
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            notificationLayout: parse(sentence).documentElement.text.length < 49 ? null : NotificationLayout.BigText,
            channelKey: 'persisnotif',
            title: 'Rappel de cours constant',
            body: sentence,
            locked: true,
            autoCancel: false,
          ),
          actionButtons: [
            NotificationActionButton(
                key: "REFRESH", label: "Actualiser", autoCancel: false, buttonType: ActionButtonType.KeepOnTop),
            NotificationActionButton(
                key: "KILL", label: "Désactiver", autoCancel: true, buttonType: ActionButtonType.Default),
          ],
        );
      } catch (e) {
        print(e);
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    print("Unscheduled $id");
  }

  ///Set an on going notification which is automatically refreshed (online or not) each hour
  static Future<void> setOnGoingNotification({bool dontShowActual = false}) async {
    //Logs for tests
    await logFile("Setting on going notification");
    print("Setting on going notification");
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Lesson> lessons = List();
    await reloadChosenApi();
    API api = APIManager(offline);
    //Login creds
    String u = await ReadStorage("username");
    String p = await ReadStorage("password");
    String url = await ReadStorage("pronoteurl");
    String cas = await ReadStorage("pronotecas");
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await api.login(u, p, url: url, cas: cas);
      } catch (e) {
        print("Error while logging");
      }
    }
    var date = DateTime.now();
    int week = await get_week(date);
    final dir = await FolderAppUtil.getDirectory();
    Hive.init("${dir.path}/offline");
    //Register adapters once
    try {
      Hive.registerAdapter(LessonAdapter());
      Hive.registerAdapter(GradeAdapter());
      Hive.registerAdapter(DisciplineAdapter());
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(HomeworkAdapter());
      Hive.registerAdapter(PollInfoAdapter());
    } catch (e) {
      print("Error while registring adapter");
    }
    if (connectivityResult == ConnectivityResult.none || !api.loggedIn) {
      Box _offlineBox = await Hive.openBox("offlineData");
      var offlineLessons = await _offlineBox.get("lessons");
      if (offlineLessons[week] != null) {
        lessons = offlineLessons[week].cast<Lesson>();
      }
    } else if (api.loggedIn) {
      try {
        lessons = await api.getNextLessons(date);
      } catch (e) {
        print("Error while collecting online lessons. ${e.toString()}");

        Box _offlineBox = await Hive.openBox("offlineData2");
        var offlineLessons = await _offlineBox.get("lessons");
        if (offlineLessons[week] != null) {
          lessons = offlineLessons[week].cast<Lesson>();
        }
      }
    }
    if (await getSetting("agendaOnGoingNotification")) {
      Lesson getActualLesson = getCurrentLesson(lessons);
      if (!dontShowActual) {
        if (await getSetting("enableDNDWhenOnGoingNotifEnabled")) {
          if (await FlutterDnd.isNotificationPolicyAccessGranted) {
            await FlutterDnd.setInterruptionFilter(
                FlutterDnd.INTERRUPTION_FILTER_NONE); // Turn on DND - All notifications are suppressed.
          } else {
            await logFile("Couldn't enabled DND");
          }
        }
        await showOngoingNotification(getActualLesson);
      }

      int minutes = await getIntSetting("lessonReminderDelay");
      await Future.forEach(lessons, (Lesson lesson) async {
        if (lesson.start.isAfter(date)) {
          try {
            if (await AndroidAlarmManager.oneShotAt(
                lesson.start.subtract(Duration(minutes: minutes)), lesson.start.hashCode, callback,
                allowWhileIdle: true, rescheduleOnReboot: true))
              print("scheduled " + lesson.start.hashCode.toString() + " $minutes minutes before.");
          } catch (e) {
            print("failed " + e.toString());
          }
        }
      });
      try {
        if (await AndroidAlarmManager.oneShotAt(
            lessons.last.end.subtract(Duration(minutes: minutes)), lessons.last.end.hashCode, callback,
            allowWhileIdle: true, rescheduleOnReboot: true)) print("Scheduled last lesson");
      } catch (e) {}
      print("Success !");
    }
  }

  static Future<void> cancelOnGoingNotification() async {
    await cancelNotification(333);

    print("Cancelled on going notification");
  }

  static Future<void> cancellAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> callback() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    List<Lesson> lessons = List();
    await reloadChosenApi();
    //Lock offline data
    Offline _offline = Offline(true);
    API api = APIManager(_offline);
    //Login creds
    String u = await ReadStorage("username");
    String p = await ReadStorage("password");
    String url = await ReadStorage("pronoteurl");
    String cas = await ReadStorage("pronotecas");
    if (connectivityResult != ConnectivityResult.none) {
      try {
        await api.login(u, p, url: url, cas: cas);
      } catch (e) {
        print("Error while logging");
      }
    }
    var date = DateTime.now();
    int week = await get_week(date);
    final dir = await FolderAppUtil.getDirectory();
    Hive.init("${dir.path}/offline");
    //Register adapters once
    try {
      Hive.registerAdapter(GradeAdapter());
      Hive.registerAdapter(DisciplineAdapter());
      Hive.registerAdapter(DocumentAdapter());
      Hive.registerAdapter(HomeworkAdapter());
      Hive.registerAdapter(LessonAdapter());
      Hive.registerAdapter(PollInfoAdapter());
    } catch (e) {
      print("Error while registring adapter");
    }
    if (connectivityResult == ConnectivityResult.none || !api.loggedIn) {
      Box _offlineBox = await Hive.openBox("offlineData");
      var offlineLessons = await _offlineBox.get("lessons");
      if (offlineLessons[week] != null) {
        lessons = offlineLessons[week].cast<Lesson>();
      }
    } else if (api.loggedIn) {
      try {
        lessons = await api.getNextLessons(date);
      } catch (e) {
        print("Error while collecting online lessons. ${e.toString()}");

        Box _offlineBox = await Hive.openBox("offlineData");
        var offlineLessons = await _offlineBox.get("lessons");
        if (offlineLessons[week] != null) {
          lessons = offlineLessons[week].cast<Lesson>();
        }
      }
    }
    Lesson currentLesson = getCurrentLesson(lessons);
    Lesson nextLesson = getNextLesson(lessons);
    Lesson lesson;
    //Show next lesson if this one is after current datetime
    if (nextLesson != null && nextLesson.start.isAfter(DateTime.now())) {
      if (await getSetting("enableDNDWhenOnGoingNotifEnabled")) {
        if (await FlutterDnd.isNotificationPolicyAccessGranted) {
          await FlutterDnd.setInterruptionFilter(
              FlutterDnd.INTERRUPTION_FILTER_NONE); // Turn on DND - All notifications are suppressed.
        } else {
          await logFile("Couldn't enabled DND");
        }
      }
      lesson = nextLesson;
      await showOngoingNotification(lesson);
    } else {
      final prefs = await SharedPreferences.getInstance();
      bool value = prefs.getBool("disableAtDayEnd");
      print(value);
      print(await getSetting("disableAtDayEnd"));
      if (await getSetting("disableAtDayEnd")) {
        await cancelOnGoingNotification();
      } else {
        lesson = currentLesson;
        await showOngoingNotification(lesson);
      }
    }
    //Logs for tests
    if (lesson != null) {
      await logFile(
          "Persistant notification next lesson callback triggered for the lesson ${lesson.disciplineCode} ${lesson.room}");
    } else {
      await logFile("Persistant notification next lesson callback triggered : you are in break.");
    }
  }
}
