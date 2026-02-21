import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/screens/chewie_screen.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../models/exercise_detail_response.dart';
import '../components/count_down_progress_indicator1.dart';
import '../extensions/colors.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/extension_util/list_extensions.dart';
import '../extensions/system_utils.dart';
import '../extensions/text_styles.dart';
import '../extensions/time_formatter.dart';
import '../extensions/widgets.dart';
import '../main.dart';
import '../models/models.dart';
import 'youtube_player_screen.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'dart:async';
import 'package:flutter_chrome_cast/widgets/mini_controller.dart';

class ExerciseDurationScreen2 extends StatefulWidget {
  static String tag = '/ExerciseDurationScreen';
  final ExerciseDetailResponse? mExerciseModel;
  final String? workOutId;

  ExerciseDurationScreen2(this.mExerciseModel, this.workOutId);

  @override
  ExerciseDurationScreen2State createState() => ExerciseDurationScreen2State();
}

class ExerciseDurationScreen2State extends State<ExerciseDurationScreen2> {
  CountDownController1 mCountDownController1 = CountDownController1();
  var mode = "portrait";

  Duration? duration;
  FlutterTts? flutterTts;
  int i = 0;
  int? mLength;
  Workout? _workout;
  Tabata? _tabata;

  List<String>? mExTime = [];
  List<String>? mRestTime = [];
  int? bufferDelay;
  late YoutubeMetaData videoMetaData;
  String? videoId = '';

  bool visibleOption = true;
  bool? isChanged = false;
  GoogleCastOptions? options;


  @override
  initState() {
    super.initState();
    print("dgdfgdfgdfgdfgdfg");
    if (widget.mExerciseModel!.data!.sets != null) {
      widget.mExerciseModel!.data!.sets!.forEachIndexed((element, index) {
        mExTime!.add(element.time.toString());
        mRestTime!.add(element.rest.toString());
        setState(() {});
      });
      _tabata = Tabata(
          sets: 1,
          reps: widget.mExerciseModel!.data!.sets!.length,
          startDelay: Duration(seconds: 3),
          exerciseTime: mExTime,
          restTime: mRestTime,
          breakTime: Duration(seconds: 60),
          status: widget.mExerciseModel?.data?.based == "reps" ? "reps" : "second");
    }

    init();

    if (videoId != null) videoId = YoutubePlayer.convertUrlToId(widget.mExerciseModel?.data?.videoUrl ?? '');
    if (flutterTts != null) flutterTts?.awaitSpeakCompletion(true);
    initPlatformState();
    GoogleCastDiscoveryManager.instance.startDiscovery();
    GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
      print("Devices Found: ${devices.map((e) => e.friendlyName).join(", ")}");
    });

    GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      print("Session updated: $session");
    });
  }

  Future<void> initPlatformState() async {
    try {
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      print("-----------24>>>>${appId}");

      if (Platform.isIOS) {
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        );
      } else if (Platform.isAndroid) {
        options = GoogleCastOptionsAndroid(
          appId: appId,
        );
      }

      await GoogleCastContext.instance.setSharedInstanceWithOptions(options!);
      print("GoogleCastContext initialized successfully");
    } catch (e, s) {
      print('Error initializing CastContext37: ${e.toString()}');
      print('Error initializing CastContext38: ${s.toString()}');
    }
  }

  init() async {
    if (widget.mExerciseModel!.data!.sets != null) {
      mLength = widget.mExerciseModel!.data!.sets!.length - 1;
    }
    _workout = Workout(_tabata!, _onWorkoutChanged);
    _start();
  }

  setExerciseApi() async {
    Map? req = {"workout_id": widget.workOutId ?? '', "exercise_id": widget.mExerciseModel?.data?.id ?? ''};
    await setExerciseHistory(req).then((value) {
      if (mounted) setState(() {});
    }).catchError((e) {});
  }

  @override
  dispose() {
    GoogleCastSessionManager.instance.endSessionAndStopCasting;
    _workout!.dispose();
    super.dispose();
  }

  void exitScreen() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    finish(context);
  }


  _onWorkoutChanged() async {
    if (_workout!.step == WorkoutState.finished) {
      await setExerciseApi();
      Navigator.pop(context);
     // finish(context);
    }
    if(mounted)this.setState(() {});
  }


/*  _onWorkoutChanged() async {
    if (_workout!.step == WorkoutState.finished) {
      await setExerciseApi();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
         / Navigator.pop(context);
        }
      });
    } else if (mounted) {
      setState(() {});
    }
  }*/

  _start() {
    _workout!.start();
  }

  Widget dividerHorizontalLine({bool? isSmall = false}) {
    return Container(
      height: isSmall == true ? 40 : 65,
      width: 4,
      color: whiteColor,
    );
  }

  Widget mSetText(String value, {String? value2}) {
    return Text(value, style: boldTextStyle(size: 18)).center();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Duration parseDuration(String durationString) {
    List<String> components = durationString.split(':');

    int hours = int.parse(components[0]);
    int minutes = int.parse(components[1]);
    int seconds = int.parse(components[2]);

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  Widget mData(List<Sets> strings) {
    List<Widget> list = [];
    for (var i = 0; i < strings.length; i++) {
      list.add(new Text(strings[i].time.toString()));
    }
    return new Row(children: list);
  }

  @override
  Widget build(BuildContext context) {
    print("--------159>>>${widget.mExerciseModel!.data!.videoUrl}");

    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      mode = "landScape";
    } else {
      mode = "portrait";
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 56),
        child: Visibility(
            visible: mode == 'portrait' ? true : false,
            child: appBarWidget(widget.mExerciseModel!.data!.title.validate(), context: context, actions: [
             /* StreamBuilder<GoogleCastSession?>(
                  stream: GoogleCastSessionManager.instance.currentSessionStream,
                  builder: (context, snapshot) {
                    final bool isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected;
                    final devices = snapshot.data ?? [];
                    return Row(
                      children: [
                        IconButton(
                            onPressed: GoogleCastSessionManager.instance.endSessionAndStopCasting,
                            icon: Icon(
                              isConnected ? Icons.cast_connected : Icons.cast,
                              color: primaryColor,
                            )),
                      ],
                    );
                  }),*/
              StreamBuilder<List<GoogleCastDevice>>(
                stream: GoogleCastDiscoveryManager.instance.devicesStream,
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? [];
                  bool? isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected;
                  print("---------232>>>${isConnected}");

                  return IconButton(
                      onPressed: () {
                        /*if(isConnected==true){
                          GoogleCastSessionManager.instance.endSessionAndStopCasting;
                        }else{

                        }*/
                        _loadQueue(devices.first);
                      },
                      icon: Icon(
                        isConnected ? Icons.cast_connected: Icons.cast_outlined,
                        color: primaryColor,
                      ));
                },
              ),
            ])),
      ),
      body: SingleChildScrollView(
        physics: mode == 'portrait' ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.mExerciseModel!.data!.videoUrl.validate().contains("https://youtu") || widget.mExerciseModel!.data!.videoUrl.validate().contains("https://www.youtu")
                ? AspectRatio(
                    aspectRatio: mode == "portrait" ? 12 / 7 : 15 / 7,
                    child: YoutubePlayerScreen(
                      url: widget.mExerciseModel!.data!.videoUrl.validate(),
                      img: widget.mExerciseModel!.data!.exerciseImage.validate(),
                      autoPlay: true,
                    ))
                : ChewieScreen(
                    url: widget.mExerciseModel!.data!.videoUrl.validate(),
                    image: widget.mExerciseModel!.data!.exerciseImage.validate(),
                    autoPlay: true,
                  ).center(),
            30.height,
            if (widget.mExerciseModel!.data!.sets != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${_workout!.rep}/${widget.mExerciseModel!.data!.sets!.length.toString()}', style: boldTextStyle(size: 18)),
                      Text(
                        languages.lblSets,
                        style: secondaryTextStyle(),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      _workout!.rep >= 1
                          ? mSetText(widget.mExerciseModel!.data!.based == "reps"
                              ? widget.mExerciseModel!.data!.sets![_workout!.rep - 1].reps.toString()
                              : widget.mExerciseModel!.data!.sets![_workout!.rep - 1].time.toString())
                          : mSetText("-"),
                      Text(
                        widget.mExerciseModel!.data!.based == "reps" ? languages.lblReps : languages.lblSecond,
                        style: secondaryTextStyle(),
                      )
                    ],
                  ),
                ],
              ).paddingSymmetric(horizontal: 16),
            50.height,
            Container(child: FittedBox(child: Text(formatTime1(_workout?.timeLeft), style: boldTextStyle(size: 110)))),
            16.height,
          ],
        ).center(),
      ),
    );
  }



  _loadQueue(GoogleCastDevice device) async {
    await GoogleCastSessionManager.instance.startSessionWithDevice(device);
    await GoogleCastRemoteMediaClient.instance.queueLoadItems(
      [
        GoogleCastQueueItem(
          activeTrackIds: [0],
          mediaInformation: GoogleCastMediaInformationIOS(
           // contentId: '0',
            contentId: 'XJoFZQqTZ5g',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(widget.mExerciseModel!.data!.videoUrl.validate()),
           // contentType: 'video/mp4',
            contentType: 'video/youtube',
            metadata: GoogleCastMovieMediaMetadata(
              title: '',
             // studio: 'Blender Inc',
              studio: 'YouTube',
              releaseDate: DateTime(2011),
              images: [
                GoogleCastImage(
                  url: Uri.parse('https://i.ytimg.com/vi_webp/gWw23EYM9VM/maxresdefault.webp'),
                  height: 480,
                  width: 854,
                ),
              ],
            ),
            tracks: [
              GoogleCastMediaTrack(
                trackId: 0,
                type: TrackType.TEXT,
                trackContentId: Uri.parse('https://raw.githubusercontent.com/felnanuke2/flutter_cast/master/example/assets/VEED-subtitles_Blender_Foundation_-_Elephants_Dream_1024.vtt').toString(),
                trackContentType: 'text/vtt',
                name: 'English',
                language: RFC5646_LANGUAGE.ENGLISH,
              ),
            ],
          ),
        ),
        GoogleCastQueueItem(
          preLoadTime: const Duration(seconds: 15),
          mediaInformation: GoogleCastMediaInformationIOS(
           // contentId: '1',
            contentId: 'XJoFZQqTZ5g',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(widget.mExerciseModel!.data!.videoUrl.validate()),
            contentType: 'video/youtube',
            metadata: GoogleCastMovieMediaMetadata(
              title: '',
              subtitle: null,
              releaseDate: DateTime(2011),
             // studio: 'Vlc Media Player',
              studio: 'YouTube',
              images: [
                GoogleCastImage(
                  url: Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'),
                  height: 480,
                  width: 854,
                ),
              ],
            ),
          ),
        ),
      ],
      options: GoogleCastQueueLoadOptions(
        startIndex: 0,
        repeatMode: GoogleCastMediaRepeatMode.ALL,
        playPosition: const Duration(seconds: 30),
      ),
    );
  }

}
