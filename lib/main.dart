import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
// import 'package:workmanager/workmanager.dart';
import 'package:background_fetch/background_fetch.dart';

//! PREPARATIONS FOR ANDROID
/// https://pub.dev/packages/background_fetch [READ] SETUP HERE FOR BACKGROUND UPDATE
/// because android security changes fast enough, so better see updated documentation
/// ------------
/// android/build.gradle line-2    [ext.kotlin_version] must be 1.9.0
/// android/app/build.gradle line-27    [compileSdkVersion] must be 34
/// android/app/build.gradle line-48    [minSdkVersion] must be 21
/// ------------
/// android\app\src\main\AndroidManifest.xml  [line_27_to_35] --REQUIRED BY HOME_WIDGET PACKAGE. COPIED FROM DOCUMENTATION
/// ------------
/// android\app\src\main\res theres [TWO_FOLDERS], [LAYOUT] and [XML], copy them. filename in folder xml is change-able but must be same with [AndroidManifest]
/// ------------
/// android\app\src\main\kotlin\com\example\widget_simplest
/// HERE copy a change-able [kt] that name must be same with [AndroidManifest]. NOT the [MainActivity.kt] but the another one
/// also the class name should the same with what we call "androidWidget" in flutter code
/// dont forget to change com.example.project_name at line 1

void configureBackgroundFetch() {
  BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15, // Call every 15 minutes
      stopOnTerminate: false,
      enableHeadless: true,
      requiredNetworkType: NetworkType.NONE, // No network requirements
    ),
    (String taskId) async {
      // This is the fetch event callback where you call your function.
      print("=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
      print("[BackgroundFetch] Event received $taskId");
      await GoUpdate.widget();
      // Always call finish when your task is done
      BackgroundFetch.finish(taskId);
    },
    (String taskId) async {
      // This handles task timeouts
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    },
  ).then((int status) {
    print('[BackgroundFetch] configure success: $status');
  }).catchError((e) {
    print('[BackgroundFetch] configure FAILURE: $e');
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // REQUIRED by background_fetch
  configureBackgroundFetch();
  print('${DateTime.now().minute}:${DateTime.now().second} INITIAL START');
  runApp(const Aplikasi());
}

class Aplikasi extends StatefulWidget {
  const Aplikasi({super.key});

  @override
  State<Aplikasi> createState() => _AplikasiState();
}

class _AplikasiState extends State<Aplikasi> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // for in-app ui, updating widget every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      setState(() {});
    });
    // initializing the widget when app opened first time
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      WidgetConfig.initialize().then((value) => GoUpdate.widget());
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer on dispose, avoiding callback error
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TheWidget(currentTime: _currentTime),
              //
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => GoUpdate.widget(),
                child: const Text('Update Widget'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================

class GoUpdate {
  static widget() {
    WidgetConfig.update(TheWidget(currentTime: DateTime.now()));
  }
}

// =========================================================================

class TheWidget extends StatelessWidget {
  const TheWidget({super.key, required this.currentTime});

  final DateTime currentTime;

  @override
  Widget build(BuildContext context) {
    List<Color> bgRand = [Colors.red, Colors.black, Colors.blue, Colors.green];
    List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    TextStyle customStyle = const TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25);

    return Container(
      color: bgRand[currentTime.minute ~/ 15.round()],
      width: 170,
      height: 170,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${currentTime.hour}:${currentTime.minute}:${currentTime.second}',
            style: customStyle,
          ),
          const SizedBox(height: 10),
          Text(
            '${days[currentTime.weekday]}, ${currentTime.day}/${currentTime.month}',
            style: customStyle,
          ),
        ],
      ),
    );
  }
}

// =========================================================================

/// all here are [STATICS] from native folders. you can create a separated file for this.s
String groupId = 'group.widget_simplest_group';
String iosWidget = 'simplest_widget_mine';
String androidWidget = 'SimplestWidgetMine';

// =========================================================================

class WidgetConfig {
  static Future<void> update(Widget widget) async {
    // Render the widget and capture the image data
    String imageData = await HomeWidget.renderFlutterWidget(
      widget, // hover on .renderFlutterWidget to see documentation
      key: 'filename',
      pixelRatio: 4.0, // Adjust pixel ratio for desired image quality
      logicalSize: const Size(160, 320), // Set desired size for the widget
    );

    // Update the home screen widget using home_widget
    await HomeWidget.saveWidgetData('filename', imageData);
    await HomeWidget.updateWidget(
        iOSName: iosWidget, androidName: androidWidget);
  }

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(groupId);
  }
}
