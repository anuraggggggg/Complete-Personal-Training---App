import 'package:flutter/material.dart';
import '../../extensions/extension_util/int_extensions.dart';
import '../../extensions/extension_util/widget_extensions.dart';
import '../components/HtmlWidget.dart';
import '../extensions/text_styles.dart';
import '../extensions/widgets.dart';

class VideoDetailScreen extends StatefulWidget {
  const VideoDetailScreen({super.key});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget("", context: context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // mExerciseModel!.data!.videoUrl.validate().contains("https://youtu")
            //     ? AspectRatio(aspectRatio: 12 / 7, child: YoutubePlayerScreen(url: mExerciseModel!.data!.videoUrl.validate(), img: mExerciseModel!.data!.exerciseImage.validate()))
            //     : ChewieScreen(mExerciseModel!.data!.videoUrl.validate(), mExerciseModel!.data!.exerciseImage.validate()).center(),
            16.height,
            Text("title", style: boldTextStyle()),
            8.height,
            HtmlWidget(postContent: "widget.mExerciseInstruction.validate()").paddingSymmetric(horizontal: 8),
          ],
        ),
      ),
    );
  }
}
