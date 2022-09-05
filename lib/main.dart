import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) {
          return Scaffold(
            body: Center(
                child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/game'),
              child: const Text('Start'),
            )),
          );
        },
        '/game': (BuildContext context) {
          return const Scaffold(
            body: Center(child: GameScreen()),
          );
        },
      },
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: MyGame());
  }
}

class MyGame extends FlameGame {
  final Grid grid = Grid();
  final EndlessMap endlessMap = EndlessMap();

  @override
  Future<void>? onLoad() {
    add(grid);
    add(endlessMap);
    return super.onLoad();
  }
}

class Grid extends Component with HasGameRef<MyGame> {
  late int rows = 4;
  late int columns;
  late int mapColumns;
  late double tileSize;

  @override
  void onGameResize(Vector2 size) {
    tileSize = (size.y / rows).floorToDouble();
    columns = (size.x / tileSize).ceil();
    mapColumns = columns + 2;
    super.onGameResize(size);
  }
}

class EndlessMap extends PositionComponent with HasGameRef<MyGame> {
  late final Sprite terrainSprite;
  late final List<SpriteComponent> terrainSpritePool;

  double stepDistance = 0.0;
  int firstTerrainIndex = 0;

  @override
  Future<void> onLoad() async {
    position.x = -gameRef.grid.tileSize;

    terrainSprite = Sprite(
      await Flame.images.load('terrains.png'),
      srcPosition: Vector2(4.0, 0.0),
      srcSize: Vector2(32.0, 32.0 * 10),
    );
    terrainSpritePool = List.generate(
      gameRef.grid.mapColumns,
      (index) => SpriteComponent(sprite: terrainSprite),
    );

    for (var i = 0; i < terrainSpritePool.length; i++) {
      terrainSpritePool[i].size.x = gameRef.grid.tileSize;
      terrainSpritePool[i].position = Vector2(
        i * gameRef.grid.tileSize,
        gameRef.grid.tileSize,
      );
      add(terrainSpritePool[i]);
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    final dx = 100 * dt;
    final lastTerrainIndex = firstTerrainIndex == 0
        ? terrainSpritePool.length - 1
        : firstTerrainIndex - 1;

    if (stepDistance + dx >= gameRef.grid.tileSize) {
      // move the first terrain to the end
      terrainSpritePool[firstTerrainIndex].size.x = gameRef.grid.tileSize;
      terrainSpritePool[firstTerrainIndex].position = Vector2(
        terrainSpritePool[lastTerrainIndex].position.x + gameRef.grid.tileSize,
        gameRef.grid.tileSize,
      );

      final gap = stepDistance + dx - gameRef.grid.tileSize;

      firstTerrainIndex = (firstTerrainIndex + 1) % terrainSpritePool.length;
      position.x -= dx;
      stepDistance = gap;
    } else {
      position.x -= dx;
      stepDistance += dx;
    }

    super.update(dx);
  }
}
