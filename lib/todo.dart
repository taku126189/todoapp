import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
//* run build_runner for code generation (create source code). When you run dart run build_runner build, build_runner looks for the configuration files in your project (like build.yaml or build_config.dart) to determine what tasks to perform during the build. These tasks might include generating code using code generation libraries like json_serializable or freezed, compiling assets, or any other custom build steps you've defined.
part 'todo.freezed.dart';
part 'todo.g.dart';

const _uuid = Uuid();

/// A read-only description of a todo-item
@freezed
class Todo with _$Todo {
  factory Todo({
    required String description,
    required String id,
    @Default(false) bool completed,
    required String createdAt,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}

/// An object that controls a list of [Todo].
//* A class which exposes a state that can change over time.
//* The state of Notifier is expected to be initialized synchronously
//* Use Notifier in favour of StateNotifier
class TodoList extends Notifier<List<Todo>> {
  @override
  List<Todo> build() =>
      []; //* Notifier does not receive anything unlike StateNotifer, but it needs to override the build method. In StateNotifer, you had to initialize the list of todos like this; TodoList(): super([]);

  void add(String description) {
    final now = DateTime.now();
    final formattedNowDate = DateFormat.yMd().format(now);
    final formattedNowTime = DateFormat.jm().format(now);
    final formattedNowWithTime = '$formattedNowDate  $formattedNowTime';
    //* Since your state is immutable, you are not allowed to do like this; state.add(todo). Instead, create a new list that contains a new items and previous items
    state = [
      ...state,
      Todo(
        id: _uuid
            .v4(), //* Assigning a new unique id to a new todo here makes sense because each todo must have its id upon creation
        description: description, createdAt: formattedNowWithTime,
      ), //* Todo(id: ...) is a new todo item added. _uuid assigns a unique id to the id parameter of the new todo and description is passed to the parameter.
    ];
  }

  void remove(Todo target) {
    //* The where method goes through every item of a List (state). If the Todo target's id is not the same as Todo todo's id, leave it in the new list (state), if it is the same, throw it away.
    state = state
        .where((todo) => todo.id != target.id)
        .toList(); //* Your state is immutable, so you are making a new list
  }

  void toggle(String id) {
    state = [
      //* for loop. todo is every item in the list (state)
      for (final todo in state)
        if (todo.id ==
            id) //* if the id of todo in the existing list is equal to the id passed to this function, pass the same id and description to the todo, but flip completed.
          todo.copyWith(completed: !todo.completed)
        else
          todo, //* If the id passed to this functio is not equal to todo, leave it
    ];
  }

  void edit({required String id, required String description}) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(
            description: description,
          )
        else
          todo,
    ];
  }
}
