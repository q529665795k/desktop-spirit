// 事件总线（解耦组件通信）
library service.event_bus;

import 'dart:async';
import '../model/pet_models.dart';
import '../service/pet_state.dart';

enum SpiritEventType {
  speak,
  showBubble,
  changeState,
  playSfx,
  vibrate,
  evolve,
  hatch,
  sleep,
  wake,
  dock,
  undock,
  feed,
  interact,
  configChanged,
}

class SpiritEvent {
  final SpiritEventType type;
  final dynamic data;

  SpiritEvent(this.type, [this.data]);

  static SpiritEvent speak(String text) => SpiritEvent(SpiritEventType.speak, text);
  static SpiritEvent showBubble(String text, {Duration? duration}) => SpiritEvent(SpiritEventType.showBubble, {'text': text, 'duration': duration ?? const Duration(seconds: 3)});
  static SpiritEvent changeState(PetState state) => SpiritEvent(SpiritEventType.changeState, state);
  static SpiritEvent playSfx(String name) => SpiritEvent(SpiritEventType.playSfx, name);
  static SpiritEvent vibrate({int duration = 50}) => SpiritEvent(SpiritEventType.vibrate, duration);
  static SpiritEvent evolve(int stage) => SpiritEvent(SpiritEventType.evolve, stage);
  static SpiritEvent hatch() => SpiritEvent(SpiritEventType.hatch);
  static SpiritEvent sleep() => SpiritEvent(SpiritEventType.sleep);
  static SpiritEvent wake() => SpiritEvent(SpiritEventType.wake);
  static SpiritEvent dock() => SpiritEvent(SpiritEventType.dock);
  static SpiritEvent undock() => SpiritEvent(SpiritEventType.undock);
  static SpiritEvent feed(Food food) => SpiritEvent(SpiritEventType.feed, food);
  static SpiritEvent interact(InteractionType type) => SpiritEvent(SpiritEventType.interact, type);
  static SpiritEvent configChanged() => SpiritEvent(SpiritEventType.configChanged);
}

class SpiritEventBus {
  SpiritEventBus._();
  static final SpiritEventBus _instance = SpiritEventBus._();
  static SpiritEventBus get I => _instance;

  final StreamController<SpiritEvent> _controller = StreamController.broadcast();

  Stream<SpiritEvent> get stream => _controller.stream;

  void emit(SpiritEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}