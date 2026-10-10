// 事件总线 - 解耦模块间通信
library events;

import 'dart:async';

abstract class SpiritEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SpiritEvent(this.type, this.data) : timestamp = DateTime.now();
}

class ConfigChangedEvent extends SpiritEvent {
  ConfigChangedEvent(String key, dynamic value)
      : super('config_changed', {'key': key, 'value': value});
}

class StateChangedEvent extends SpiritEvent {
  StateChangedEvent(String key, dynamic value)
      : super('state_changed', {'key': key, 'value': value});
}

class ActionTriggeredEvent extends SpiritEvent {
  ActionTriggeredEvent(String action, [Map<String, dynamic>? params])
      : super('action_triggered', {'action': action, 'params': params ?? {}});
}

class PetInteractionEvent extends SpiritEvent {
  PetInteractionEvent(String interaction, int value)
      : super('pet_interaction', {'interaction': interaction, 'value': value});
}

class OverlayPositionEvent extends SpiritEvent {
  OverlayPositionEvent(double x, double y)
      : super('overlay_position', {'x': x, 'y': y});
}

class EvolutionEvent extends SpiritEvent {
  EvolutionEvent(int newLevel)
      : super('evolution', {'level': newLevel});
}

class CustomAvatarChangedEvent extends SpiritEvent {
  CustomAvatarChangedEvent(String path)
      : super('custom_avatar_changed', {'path': path});
}

class SyncRequestedEvent extends SpiritEvent {
  SyncRequestedEvent(bool upload)
      : super('sync_requested', {'upload': upload});
}

class ErrorOccurredEvent extends SpiritEvent {
  ErrorOccurredEvent(String message, [StackTrace? stack])
      : super('error', {'message': message, 'stack': stack?.toString()});
}

class EventBus {
  EventBus._();
  static final EventBus instance = EventBus._();

  final _controllers = <String, StreamController<SpiritEvent>>{};

  Stream<SpiritEvent> on(String eventType) {
    return (_controllers[eventType] ??= StreamController.broadcast()).stream;
  }

  void emit(SpiritEvent event) {
    _controllers[event.type]?.add(event);
    // 也发到通用流
    _controllers['*']?.add(event);
  }

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }
}

/// Mixin for widgets that listen to events
/// Usage: class _MyWidgetState extends State<MyWidget> with EventListenerMixin<ConfigChangedEvent> { ... }
mixin EventListenerMixin<T extends SpiritEvent> on State<StatefulWidget> {
  late StreamSubscription<SpiritEvent> _subscription;
  
  Stream<SpiritEvent> get eventStream => EventBus.instance.on(_eventType);
  String get _eventType => T.toString().split('.').last;

  @override
  void initState() {
    super.initState();
    _subscription = eventStream.listen(_onEvent);
  }

  void _onEvent(SpiritEvent event) {
    if (mounted) {
      onEvent(event as T);
    }
  }

  void onEvent(T event);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}