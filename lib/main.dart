import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const BrickBreakerApp());
}

class BrickBreakerApp extends StatelessWidget {
  const BrickBreakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brick Breaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff10191d),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffd7ff64),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BrickBreakerPage(),
    );
  }
}

class BrickBreakerPage extends StatefulWidget {
  const BrickBreakerPage({super.key});

  @override
  State<BrickBreakerPage> createState() => _BrickBreakerPageState();
}

class _BrickBreakerPageState extends State<BrickBreakerPage> {
  static const int _columns = 8;
  static const int _rows = 5;
  static const double _ballRadius = 7;
  static const double _paddleWidth = 96;
  static const double _paddleHeight = 12;

  static const List<Color> _brickColors = [
    Color(0xff61d9c3),
    Color(0xffff856b),
    Color(0xffffd166),
    Color(0xff87a8ff),
    Color(0xffd88be8),
  ];

  final List<bool> _bricks = List<bool>.filled(_columns * _rows, true);
  Timer? _timer;
  Size _boardSize = Size.zero;
  Offset _ball = Offset.zero;
  Offset _velocity = const Offset(175, -250);
  double _paddlePosition = 0.5;
  int _score = 0;
  int _lives = 3;
  bool _playing = false;
  bool _gameOver = false;
  bool _won = false;

  Offset get _visibleBall => _ball == Offset.zero
      ? Offset(_boardSize.width / 2, _boardSize.height * 0.78)
      : _ball;

  Rect get _paddleRect => Rect.fromCenter(
    center: Offset(_boardSize.width * _paddlePosition, _boardSize.height - 34),
    width: _paddleWidth,
    height: _paddleHeight,
  );

  void _startOrPause() {
    if (_gameOver || _won) {
      _resetGame();
    }
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _ball = _visibleBall;
      }
    });
    _timer?.cancel();
    if (_playing) {
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    }
  }

  void _resetGame() {
    for (var index = 0; index < _bricks.length; index++) {
      _bricks[index] = true;
    }
    _ball = Offset(_boardSize.width / 2, _boardSize.height * 0.78);
    _velocity = const Offset(175, -250);
    _score = 0;
    _lives = 3;
    _gameOver = false;
    _won = false;
  }

  void _movePaddle(double x) {
    if (_boardSize.width <= 0) return;
    setState(() {
      _paddlePosition = (x / _boardSize.width).clamp(
        _paddleWidth / 2 / _boardSize.width,
        1 - _paddleWidth / 2 / _boardSize.width,
      );
    });
  }

  void _tick() {
    if (!_playing || _boardSize.isEmpty) return;
    setState(() {
      _advanceBall(const Duration(milliseconds: 16).inMicroseconds / 1000000);
    });
  }

  void _advanceBall(double seconds) {
    final radius = _ballRadius;
    var next = _ball + _velocity * seconds;

    if (next.dx - radius <= 0 || next.dx + radius >= _boardSize.width) {
      _velocity = Offset(-_velocity.dx, _velocity.dy);
      next = Offset(next.dx.clamp(radius, _boardSize.width - radius), next.dy);
    }
    if (next.dy - radius <= 0) {
      _velocity = Offset(_velocity.dx, _velocity.dy.abs());
      next = Offset(next.dx, radius);
    }

    final paddle = _paddleRect;
    if (_velocity.dy > 0 &&
        next.dy + radius >= paddle.top &&
        next.dy - radius <= paddle.bottom &&
        next.dx >= paddle.left &&
        next.dx <= paddle.right) {
      final hitOffset = ((next.dx - paddle.center.dx) / (paddle.width / 2))
          .clamp(-1.0, 1.0);
      final speed = _velocity.distance;
      final angle = hitOffset * 1.05;
      _velocity = Offset(math.sin(angle) * speed, -math.cos(angle) * speed);
      next = Offset(next.dx, paddle.top - radius);
    }

    final brickRect = _brickRectangles().toList();
    for (var index = 0; index < brickRect.length; index++) {
      if (_bricks[index] && brickRect[index].inflate(radius).contains(next)) {
        _bricks[index] = false;
        _score += 10;
        _velocity = Offset(_velocity.dx, -_velocity.dy);
        break;
      }
    }

    if (next.dy - radius > _boardSize.height) {
      _lives--;
      if (_lives == 0) {
        _playing = false;
        _gameOver = true;
        _timer?.cancel();
      } else {
        next = Offset(_boardSize.width / 2, _boardSize.height * 0.78);
        _velocity = const Offset(175, -250);
      }
    }

    if (_bricks.every((brick) => !brick)) {
      _playing = false;
      _won = true;
      _timer?.cancel();
    }
    _ball = next;
  }

  Iterable<Rect> _brickRectangles() sync* {
    const sidePadding = 14.0;
    const gap = 6.0;
    const brickHeight = 18.0;
    final width =
        (_boardSize.width - sidePadding * 2 - gap * (_columns - 1)) / _columns;
    for (var row = 0; row < _rows; row++) {
      for (var column = 0; column < _columns; column++) {
        yield Rect.fromLTWH(
          sidePadding + column * (width + gap),
          30 + row * (brickHeight + gap),
          width,
          brickHeight,
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabel = _gameOver || _won
        ? 'Play again'
        : _playing
        ? 'Pause'
        : _score > 0 || _lives < 3
        ? 'Resume'
        : 'Start game';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BRICK BREAKER',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xfff4f3e8),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Clear the board. Keep the ball alive.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xffa3b1ad)),
                        ),
                      ],
                    ),
                  ),
                  _StatDisplay(label: 'SCORE', value: '$_score'),
                  const SizedBox(width: 18),
                  _StatDisplay(label: 'LIVES', value: '$_lives'),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff34444a)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _boardSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        key: const ValueKey('game-board'),
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (details) =>
                            _movePaddle(details.localPosition.dx),
                        onPanUpdate: (details) =>
                            _movePaddle(details.localPosition.dx),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _BrickBreakerPainter(
                            bricks: _bricks,
                            brickRects: _brickRectangles().toList(),
                            brickColors: _brickColors,
                            ball: _visibleBall,
                            ballRadius: _ballRadius,
                            paddle: _paddleRect,
                            playing: _playing,
                            gameOver: _gameOver,
                            won: _won,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Color(0xffa3b1ad),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Drag anywhere on the board to move',
                      style: TextStyle(color: Color(0xffa3b1ad), fontSize: 13),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _startOrPause,
                    icon: Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    ),
                    label: Text(buttonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  const _StatDisplay({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xffa3b1ad),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xffd7ff64),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BrickBreakerPainter extends CustomPainter {
  const _BrickBreakerPainter({
    required this.bricks,
    required this.brickRects,
    required this.brickColors,
    required this.ball,
    required this.ballRadius,
    required this.paddle,
    required this.playing,
    required this.gameOver,
    required this.won,
  });

  final List<bool> bricks;
  final List<Rect> brickRects;
  final List<Color> brickColors;
  final Offset ball;
  final double ballRadius;
  final Rect paddle;
  final bool playing;
  final bool gameOver;
  final bool won;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff142126),
    );
    final gridPaint = Paint()
      ..color = const Color(0x0cffffff)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 24.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var index = 0; index < bricks.length; index++) {
      if (!bricks[index]) continue;
      final rect = RRect.fromRectAndRadius(
        brickRects[index],
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = brickColors[index ~/ 8]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          brickRects[index].deflate(2),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0x24ffffff),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(paddle, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xffd7ff64)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddle, const Radius.circular(6)),
      Paint()..color = const Color(0xffd7ff64),
    );
    canvas.drawCircle(
      ball,
      ballRadius,
      Paint()
        ..color = const Color(0xfff4f3e8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(ball, ballRadius - 1, Paint()..color = Colors.white);

    final message = won
        ? 'BOARD CLEARED'
        : gameOver
        ? 'GAME OVER'
        : playing
        ? ''
        : 'READY?';
    if (message.isNotEmpty) {
      final text = TextPainter(
        text: TextSpan(
          text: message,
          style: const TextStyle(
            color: Color(0xfff4f3e8),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset((size.width - text.width) / 2, size.height * 0.56),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrickBreakerPainter oldDelegate) => true;
}
