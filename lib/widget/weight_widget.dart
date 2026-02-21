
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:mighty_fitness/main.dart';
import 'package:mighty_fitness/utils/app_colors.dart';
import 'package:tuple/tuple.dart';

BoxDecoration bottomSheetDecoration = BoxDecoration(
  color: appStore.isDarkMode ?Colors.black :Color(0xffD9D9D9),
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(30),
    topRight: Radius.circular(30),
  ),
);

class Header extends StatefulWidget {
  const Header({
    required this.weightType,
    required this.inKg,
  });

  final WeightType weightType;
  final double inKg;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            color: appStore.isDarkMode ?Color(0xffD9D9D9) :Colors.black,
            onPressed: ()  {
              navigator.pop();
            } ,
            icon: const Icon(Icons.close),
          ),
           Text(languages.lblWeight,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: appStore.isDarkMode ?Color(0xffD9D9D9) :Colors.black)),
          IconButton(
            color: appStore.isDarkMode ?Color(0xffD9D9D9) :Colors.black,
            onPressed: () => navigator.pop<Tuple2<WeightType, double>>(
              Tuple2(widget.weightType, widget.inKg),
            ),
            icon: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}

enum WeightType {
  kg,
  lb,
}

extension WeightTypeExtension on WeightType {
  String get name {
    switch (this) {
      case WeightType.kg:
        return languages.lblLbs;
      case WeightType.lb:
        return languages.lblKg;
    }
  }

}

class Switcher extends StatefulWidget {
  final WeightType weightType;
  final ValueChanged<WeightType> onChanged;
  const Switcher({
    Key? key,
    required this.weightType,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<Switcher> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 250,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            top: 2,
            width: 121,
            height: 36,
            left: widget.weightType == WeightType.kg ? 2 : 127,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xffEC7E4A),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffFAFAFA).withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildButton(WeightType.kg),
                  _buildButton(WeightType.lb)
                ],
              ))
        ],
      ),
    );
  }

  Widget _buildButton(WeightType type) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onChanged(type);
        },
        child: Center(
          child: Text(
            type.name,
            style: const TextStyle(fontWeight: FontWeight.bold,color: Color(0xffFAFAFA)),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


class DivisionSlider extends StatefulWidget {
  final double from;
  final double max;
  final double initialValue;
  final Function(double) onChanged;
  final WeightType type;

  const DivisionSlider({
    required this.from,
    required this.max,
    required this.initialValue,
    required this.onChanged,
    required this.type,
    super.key,
  });

  @override
  State<DivisionSlider> createState() => DivisionSliderState();
}

class DivisionSliderState extends State<DivisionSlider>   {
  PageController? numbersController;
  final itemsExtension = 1000;
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;

  }

  void _updateValue() {
    value = ((((numbersController?.page ?? 0) - itemsExtension) * 10).roundToDouble() / 10).clamp(widget.from, widget.max);

    widget.onChanged(value);
  }


  @override
  Widget build(BuildContext context) {


     assert(widget.initialValue >= widget.from ||
         widget.initialValue <= widget.max);

    return Container(
      color: appStore.isDarkMode ?scaffoldColorDark:BackgroundColorImageColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
        final viewPortFraction = 1 / (constraints.maxWidth / 10);
          numbersController = PageController(
            initialPage: itemsExtension + widget.initialValue.toInt(),
            viewportFraction: viewPortFraction * 10,
          );
          numbersController?.addListener(_updateValue);


          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                '${languages.lblWeight}: ${value.toStringAsFixed(1)} ${widget.type.name}',
                style:  TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 10,
                width: 11.5,
                child: CustomPaint(
                  painter: TrianglePainter(),
                ),
              ),
              Numbers(
                itemsExtension: itemsExtension,
                controller: numbersController,
                start: widget.from.toInt(),
                end:widget.max.toInt(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    numbersController?.removeListener(_updateValue);
    numbersController?.dispose();
    super.dispose();
  }
}

class TrianglePainter extends CustomPainter {
  TrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = primaryColor;
    Paint paint2 = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(getTrianglePath(size.width, size.height), paint);
    canvas.drawPath(line(size.width, size.height), paint2);
  }

  Path getTrianglePath(double x, double y) {
    return Path()
      ..lineTo(x, 0)
      ..lineTo(x / 2, y)
      ..lineTo(0, 0);
  }

  Path line(double x, double y) {
    return Path()
      ..moveTo(x / 2, 0)
      ..lineTo(x / 2, y * 2);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return true;
  }
}

var c = Color(0xffEC7E4A);

class Numbers extends StatefulWidget {
  final PageController? controller;
  final int itemsExtension;
  final int start;
  final int end;

  const Numbers({
    required this.controller,
    required this.itemsExtension,
    required this.start,
    required this.end,
    Key? key,
  }) : super(key: key);

  @override
  State<Numbers> createState() => _NumbersState();
}

class _NumbersState extends State<Numbers> {
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 42,
      child: PageView.builder(
        pageSnapping: false,
        controller: widget.controller,
        physics: CustomPageScrollPhysics(
          start: widget.itemsExtension + widget.start.toDouble(),
          end: widget.itemsExtension + widget.end.toDouble(),
        ),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, rawIndex) {
          final index = rawIndex - widget.itemsExtension;
          return Item(index: index >= widget.start && index <= widget.end ? index : null);
        },
      ),
    );
  }
}

class Item extends StatefulWidget {
  final int? index;

  const Item({
    required this.index,
    Key? key,
  }) : super(key: key);

  @override
  State<Item> createState() => _ItemState();
}

class _ItemState extends State<Item> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          const Dividers(),
          if (widget.index != null)
            Expanded(
              child: Center(
                child: Text(
                  '${widget.index}',
                  style:  TextStyle(
                    color: appStore.isDarkMode ?Colors.white :scaffoldColorDark,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Dividers extends StatefulWidget {
  const Dividers({Key? key}) : super(key: key);

  @override
  State<Dividers> createState() => _DividersState();
}

class _DividersState extends State<Dividers> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(10, (index) {
          final thickness = index == 5 ? 1.5 : 0.5;
          return Expanded(
            child: Row(
              children: [
                Transform.translate(
                  offset: Offset(-thickness / 2, 0),
                  child: VerticalDivider(
                    thickness: thickness,
                    width: 1,
                    color: appStore.isDarkMode ?Colors.white :scaffoldColorDark,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class CustomPageScrollPhysics extends ScrollPhysics {
  final double start;
  final double end;

  const CustomPageScrollPhysics({
    required this.start,
    required this.end,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(
      parent: buildParent(ancestor),
      start: start,
      end: end,
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position,
      double velocity,
      ) {
    final oldPosition = position.pixels;
    final frictionSimulation =
    FrictionSimulation(0.4, position.pixels, velocity * 0.2);

    double newPosition = (frictionSimulation.finalX / 10).round() * 10;

    final endPosition = end * 10 * 10;
    final startPosition = start * 10 * 10;
    if (newPosition > endPosition) {
      newPosition = endPosition;
    } else if (newPosition < startPosition) {
      newPosition = startPosition;
    }
    if (oldPosition == newPosition) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      newPosition.toDouble(),
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 20,
    stiffness: 100,
    damping: 0.8,
  );
}