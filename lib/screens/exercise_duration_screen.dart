import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mighty_fitness/extensions/text_styles.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/network/rest_api.dart';
import 'package:mighty_fitness/utils/app_images.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mighty_fitness/utils/SliderCustomTrackShape.dart';
import 'package:mighty_fitness/utils/app_common.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../extensions/extension_util/string_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../../models/exercise_detail_response.dart';
import '../components/count_down_progress_indicator.dart';
import '../extensions/extension_util/context_extensions.dart';
import '../extensions/extension_util/int_extensions.dart';
import '../extensions/system_utils.dart';
import '../extensions/widgets.dart';
import '../utils/app_colors.dart';
import 'youtube_player_screen.dart';

class ExerciseDurationScreen extends StatefulWidget {
  static String tag = '/ExerciseDurationScreen';
  final ExerciseDetailResponse? mExerciseModel;
  final String? workOutId;

  ExerciseDurationScreen(this.mExerciseModel, this.workOutId);

  @override
  ExerciseDurationScreenState createState() => ExerciseDurationScreenState();
}

class ExerciseDurationScreenState extends State<ExerciseDurationScreen> with TickerProviderStateMixin {
  CountDownController mCountDownController = CountDownController();
  var mode = "portrait";
  bool _isInitialized = false;
  String? durationstring;
  Duration? duration1;
  String _currentTime = '0:00';
  String _totalTime = '0:00';
  double _videoProgress = 0.0;

  bool _isBottomSheetOpen = false;

  late FlutterTts flutterTts;

//  late VideoPlayerController _videoPlayerController1;
  late VideoPlayerController _controller;
  GoogleCastOptions? options;

  int? bufferDelay;
  bool? isChanged = false;
  YoutubePlayerController? youtubePlayerController;
  TextEditingController? _idController;
  late TextEditingController _seekToController;
  late PlayerState _playerState;
  late YoutubeMetaData videoMetaData;
  bool _isPlayerReady = false;
  String? videoId = '';

  bool visibleOption = true;
  bool isFirstCall = true;

  bool _isCurrentlyLandscape = false;
  bool _isShowControllar = false;
  bool _isMuted = false;
  bool _isPlaying = false;
  Timer? _hideTimer;
  bool _isDraggingSlider = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    print("----------229>>>${ExerciseDurationScreenState}");
    init();
    flutterTts = FlutterTts();
    initializePlayer();
    _setOrientation(isLandscape: false);
    initPlatformState();
    GoogleCastDiscoveryManager.instance.startDiscovery();
    GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
      print("Devices Found: ${devices.map((e) => e.friendlyName).join(", ")}");
    });
    GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      print("Session updated: $session");
    });
  }

  init() async {
    durationstring = widget.mExerciseModel!.data!.duration.validate();
    duration1 = parseDuration(durationstring!);
    if (widget.mExerciseModel!.data!.duration != null && widget.mExerciseModel!.data!.videoUrl.validate().contains("https://youtu"))
      duration1 = parseDuration(widget.mExerciseModel!.data!.duration.validate());

    if (videoId != null) videoId = YoutubePlayer.convertUrlToId(widget.mExerciseModel!.data!.videoUrl.validate());
    if (videoId != null)
      youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId!,
        flags: YoutubePlayerFlags(
          mute: false,
          autoPlay: true,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
          showLiveFullscreenButton: false,
        ),
      )..addListener(listener);
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    if (youtubePlayerController != null)
      youtubePlayerController!.addListener(() {
        if (_playerState == PlayerState.playing) {
          if (isChanged == true) {
            mCountDownController.resume();
            isChanged = false;
          }
        }
        if (_playerState == PlayerState.paused) {
          mCountDownController.pause();
          flutterTts.pause();
          isChanged = true;
        }
      });
    videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  setExerciseApi() async {
    Map? req = {"workout_id": widget.workOutId ?? '', "exercise_id": widget.mExerciseModel?.data?.id ?? ''};
    await setExerciseHistory(req).then((value) {
      if (mounted) setState(() {});
    }).catchError((e) {});
  }

  Future<void> initializePlayer() async {
    print("-------------135>>>${widget.mExerciseModel?.data?.videoUrl ?? ''}");
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mExerciseModel?.data?.videoUrl ?? ''));
    // await Future.wait([_controller.initialize()]);
    await _controller.initialize();
    _controller.setLooping(true);
    _isInitialized = true;
    setState(() {});
    if (_controller.value.isInitialized) {
      _controller.play();
      _isPlaying = true;
    }
    _controller.addListener(() {
      if (_controller.value.isInitialized) {
        _videoProgress = _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds;
        //_controller.setVolume(0.0);
        _currentTime = _formatDuration(_controller.value.position);
        _totalTime = _formatDuration(_controller.value.duration);
        if (mounted) setState(() {});
      }

      if (_controller.value.isPlaying) {
        print('Video is playing');
        if (isChanged == true) {
          mCountDownController.resume();
          isChanged = false;
        }
      } else if (_controller.value.isBuffering) {
        print('Video is buffering');
      } else if (_controller.value.isInitialized) {
        mCountDownController.pause();
        flutterTts.pause();
        isChanged = true;
      } else {
        print('Video controller is in an unknown state');
      }
    });
    setState(() {});
  }

  Future<void> initPlatformState({int retryCount = 0, int maxRetries = 3}) async {
    try {
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      print("Initializing Google Cast with appId: $appId");

      if (Platform.isIOS) {
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        );
      } else if (Platform.isAndroid) {
        options = GoogleCastOptionsAndroid(
          appId: appId,
        );
      } else {
        throw UnsupportedError("Platform not supported");
      }

      // Initialize Cast context
      await GoogleCastContext.instance.setSharedInstanceWithOptions(options!);
      print("GoogleCastContext initialized successfully");
    } catch (e, s) {
      print('Error initializing CastContext: $e');
      print('Stack trace: $s');

      // Retry logic
      if (retryCount < maxRetries) {
        print("Retrying initialization (attempt ${retryCount + 1}/$maxRetries)...");
        await Future.delayed(Duration(seconds: retryCount + 1));
        return initPlatformState(retryCount: retryCount + 1, maxRetries: maxRetries);
      } else {
        print("Failed to initialize CastContext after $maxRetries attempts.");
        rethrow;
      }
    }
  }

  int currPlayIndex = 0;

  Future<void> toggleVideo() async {
    await _controller.pause();
    currPlayIndex += 1;
    await initializePlayer();
  }

  void _toggleVolume() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
      GoogleCastSessionManager.instance.setDeviceVolume(_isMuted ? 0.0 : 1.0);
      _isPlaying == true ? GoogleCastRemoteMediaClient.instance.play() : GoogleCastRemoteMediaClient.instance.pause();
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _toggleController() {
    setState(() {
      _isShowControllar = !_isShowControllar;
    });

    _hideTimer?.cancel();

    if (_isShowControllar) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isShowControllar = false;
          });
        }
      });
    }
  }

  @override
  dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.dispose();
    if (youtubePlayerController != null) youtubePlayerController!.pause();
    if (youtubePlayerController != null) youtubePlayerController!.dispose();
    if (_idController != null) _idController!.dispose();
    _seekToController.dispose();
    GoogleCastSessionManager.instance.endSessionAndStopCasting();
    GoogleCastSessionManager.instance.endSession();
    _hideTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  void exitScreen() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
    finish(context);
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        GoogleCastRemoteMediaClient.instance.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        GoogleCastRemoteMediaClient.instance.play();
        _isPlaying = true;
      }
    });
  }

  void _skipForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + Duration(seconds: 10);

    if (newPosition < _controller.value.duration) {
      _controller.seekTo(newPosition);
      if (GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected) {
        GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: newPosition));
        _isPlaying == true ? GoogleCastRemoteMediaClient.instance.play() : GoogleCastRemoteMediaClient.instance.pause();
      }
    } else {
      _controller.seekTo(_controller.value.duration);
      if (GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected) {
        GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: _controller.value.duration));
        _isPlaying == true ? GoogleCastRemoteMediaClient.instance.play() : GoogleCastRemoteMediaClient.instance.pause();
      }
    }
  }

  void _skipBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _controller.seekTo(newPosition);
      if (GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected) {
        GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: newPosition));
        _isPlaying == true ? GoogleCastRemoteMediaClient.instance.play() : GoogleCastRemoteMediaClient.instance.pause();
      }
    } else {
      _controller.seekTo(Duration.zero);
      if (GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected) {
        GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: Duration.zero));
        _isPlaying == true ? GoogleCastRemoteMediaClient.instance.play() : GoogleCastRemoteMediaClient.instance.pause();
      }
    }
  }

  void _setOrientation({required bool isLandscape}) {
    setState(() {
      _isCurrentlyLandscape = isLandscape;
    });

    SystemChrome.setPreferredOrientations([
      if (isLandscape) ...[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ] else ...[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]
    ]);
  }

  void _toggleOrientation() {
    _setOrientation(isLandscape: !_isCurrentlyLandscape);
  }

  void listener() {
    if (_isPlayerReady && mounted && !youtubePlayerController!.value.isFullScreen) {
      setState(() {
        _playerState = youtubePlayerController!.value.playerState;
        videoMetaData = youtubePlayerController!.metadata;
      });
    }
  }

  @override
  void deactivate() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    if (youtubePlayerController != null) youtubePlayerController!.pause();
    super.deactivate();
  }

  Duration parseDuration(String durationString) {
    List<String> components = durationString.split(':');

    int hours = int.parse(components[0]);
    int minutes = int.parse(components[1]);
    int seconds = int.parse(components[2]);

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double eachPart = (duration1?.inSeconds.toInt() ?? 0) / 3;

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
              StreamBuilder<List<GoogleCastDevice>>(
                stream: GoogleCastDiscoveryManager.instance.devicesStream,
                builder: (context, snapshot) {
                  bool? isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected;
                  GoogleCastSessionManager.instance.setDeviceVolume(0);
                  return Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            if (widget.mExerciseModel?.data?.videoUrl != null &&
                                (widget.mExerciseModel!.data!.videoUrl!.contains("https://youtu") ||
                                    widget.mExerciseModel!.data!.videoUrl!.contains("https://www.youtu"))) {


                              toast("Casting not supported");
                            }else{
                              _showDeviceBottomSheet(context);

                            }
                          },
                          icon: Icon(
                            isConnected ? Icons.cast_connected : Icons.cast_outlined,
                            color: primaryColor,
                          )),
                      if(Platform.isIOS)...[
                        GestureDetector(onTap: (){
                          if (widget.mExerciseModel?.data?.videoUrl != null &&
                              (widget.mExerciseModel!.data!.videoUrl!.contains("https://youtu") || widget.mExerciseModel!.data!.videoUrl!.contains("https://www.youtu"))) {
                            toast("Casting not supported");
                          } else {
                            _showDeviceBottomSheet(context);
                          }

                        }, child: Image.asset(ic_broadcast,color: isConnected?primaryColor:Colors.black54, width: 30, height: 30))

                      ],
                      15.width,
                    ],
                  );
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
                : AspectRatio(
                    aspectRatio: mode == "portrait" ? 12 / 7 : 12 / 7,
                    child: _isInitialized
                        ? GestureDetector(
                            onTap: _toggleController,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(_controller),
                                    Positioned(left: 0, right: 0, bottom: 0, top: 0, child: _controls()),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              cachedImage(widget.mExerciseModel!.data!.exerciseImage.validate(), fit: BoxFit.fill, height: context.height(), width: double.infinity).cornerRadiusWithClipRRect(0),
                              if (!_controller.value.isInitialized) ...[
                                Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ],
                            ],
                          ),
                  ).center().paddingSymmetric(horizontal: 4),
            34.height,
            SizedBox(
              height: 150,
              width: context.width(),
              child: CountDownProgressIndicator(
                controller: mCountDownController,
                strokeWidth: 15,
                valueColor: primaryColor,
                backgroundColor: primaryOpacity,
                initialPosition: 0,
                duration: widget.mExerciseModel?.data?.duration.isEmptyOrNull ?? true ? widget.mExerciseModel?.data?.duration?.toInt() ?? 0 : duration1?.inSeconds ?? 0,
                timeFormatter: (seconds) {
                  if (isFirstCall == true) {
                    if (seconds == eachPart) {
                      setExerciseApi();
                      isFirstCall = false;
                    }
                  }
                  return Duration(seconds: seconds).toString().split('.')[0].padLeft(8, '0');
                },
                text: 'mm:ss',
                onComplete: () {
                  if (_isBottomSheetOpen) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                  }
                  // toast("done");
                },
              ),
            ).center(),
            34.height,
          ],
        ).center(),
      ),
    );
  }

  Widget _controls() {
    return Visibility(
      visible: _isShowControllar == true,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 65),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(onTap: _skipBackward, child: Image.asset(ic_backward, height: 30, width: 30)),
                ),
                20.width,
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlay,
                  ),
                ),
                20.width,
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(onTap: _skipForward, child: Image.asset(ic_forward, width: 30, height: 30)),
                ),
              ],
            ).expand(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            _currentTime,
                            style: boldTextStyle(color: Colors.white, size: 13),
                          ),
                          Text(
                            ' / ${_totalTime}',
                            style: primaryTextStyle(color: Colors.white, size: 13),
                          ),
                          IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              size: 30,
                            ),
                            onPressed: _toggleVolume,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isCurrentlyLandscape ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: _toggleOrientation,
                          ),
                        ],
                      )
                    ],
                  ),
                  Container(
                    height: 5,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5.0,
                        overlayShape: SliderComponentShape.noOverlay,
                        //overlayShape: SliderComponentShape.noThumb,
                        thumbColor: primaryColor,
                        trackShape: SliderCustomTrackShape(),
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        value: _videoProgress,
                        onChanged: (value) {
                          setState(() {
                            _isDraggingSlider = true;
                            _videoProgress = value;
                          });
                        },
                        onChangeStart: (value) {
                          setState(() {
                            _isDraggingSlider = true;
                          });
                        },
                        onChangeEnd: (value) {
                          final milliseconds = (_controller.value.duration.inMilliseconds * value).toInt();
                          _controller.seekTo(Duration(milliseconds: milliseconds));
                          if (GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.ConnectionStateConnected) {
                            GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: Duration(milliseconds: milliseconds)));
                            _isPlaying == true ? GoogleCastRemoteMediaClient.instance.play() : GoogleCastRemoteMediaClient.instance.pause();
                          }

                          setState(() {
                            _isDraggingSlider = false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
             contentId: '0',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(widget.mExerciseModel?.data?.videoUrl ?? ''),
           // contentUrl: Uri.parse('http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
            contentType: 'video/mp4',
            metadata: GoogleCastMovieMediaMetadata(
              title: '',
              // studio: 'Blender Inc',
              studio: 'Media Player',
              releaseDate: DateTime(2011),
              images: [
                GoogleCastImage(
                  url: Uri.parse(widget.mExerciseModel?.data?.exerciseImage ?? ''),
                  height: 480,
                  width: 854,
                ),
              ],
            ),
            tracks: [
              GoogleCastMediaTrack(
                trackId: 0,
                type: TrackType.TEXT,
                trackContentId: Uri.parse(widget.mExerciseModel?.data?.exerciseImage ?? '').toString(),
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
            contentId: '1',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(widget.mExerciseModel!.data!.videoUrl.validate()),
            //contentUrl: Uri.parse('http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
            contentType: 'video/youtube',
            metadata: GoogleCastMovieMediaMetadata(
              title: '',
              subtitle: null,
              releaseDate: DateTime(2011),
              studio: 'Media Player',
              images: [
                GoogleCastImage(
                  url: Uri.parse(widget.mExerciseModel?.data?.exerciseImage ?? ''),
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

  Widget _buildDeviceList() {
    return StreamBuilder<List<GoogleCastDevice>>(
      stream: GoogleCastDiscoveryManager.instance.devicesStream,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];

        if (devices.isEmpty) {
          return const Center(child: Text('No devices found.'));
        }

        return ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return ListTile(
              title: Text(device.friendlyName, style: primaryTextStyle(color: primaryColor)),
              subtitle: Text(device.modelName ?? '', style: primaryTextStyle(color: primaryColor)),
              onTap: () => _loadQueue(device),
            );
          },
        );
      },
    );
  }

  void _showDeviceBottomSheet(BuildContext context) {
    setState(() {
      _isBottomSheetOpen = true;
    });
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      elevation: 0,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      transitionAnimationController: AnimationController(vsync: this, duration: const Duration(seconds: 1)),
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        elevation: 10,
        child: Container(
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? Colors.black54 : Colors.black12,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          height: MediaQuery.of(context).size.height * 0.3,
          child: _buildDeviceList(),
        ),
      ),
    ).then((_) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    });
  }
}
