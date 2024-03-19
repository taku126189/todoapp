//* The import of 'package:cloud_firestore/cloud_firestore.dart' is unnecessary because all of the used elements are also provided by the import of 'package:todo_app/date_time_timestamp_converter.dart'.
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:todo_app/date_time_timestamp_converter.dart';
import 'package:uuid/uuid.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
//* run build_runner for code generation (create source code). When you run dart run build_runner build, build_runner looks for the configuration files in your project (like build.yaml or build_config.dart) to determine what tasks to perform during the build. These tasks might include generating code using code generation libraries like json_serializable or freezed, compiling assets, or any other custom build steps you've defined.
part '../todo.freezed.dart';
part '../todo.g.dart';

const _uuid = Uuid();

/// A read-only description of a todo-item
@freezed
class Todo with _$Todo {
  factory Todo({
    required String description,
    required String id,
    @Default(false) bool completed,
    @DateTimeTimestampConverter() required DateTime createdAt,
  }) = _Todo;

  //*  fromJson method is used for creating a Dart object from JSON data (Map). A necessary factory constructor for creating a new User instance
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

  Future<void> add(String description) async {
    try {
      final now = DateTime.now();
      final id = _uuid.v4();
      final newTodo = Todo(id: id, description: description, createdAt: now);
      //* Instance Firestore
      final db = FirebaseFirestore.instance;
      //* Create Map<String, dynamic> for storing the data in firestore
      final todo = newTodo.toJson();
      //* Store data in firestore. Use set method instead of add because it allows overwrting the stored data. By adding id as document path, it can avoid overwriting the todo item added before
      //* A new item should be added to Firestore before state = [...sate, newTodo,]; because if some error happned in the process of adding date to firestore (e.g., internet connection error etc), you should stop adding item to the state; otherwise the data in the state and the one in Firestore will be different.
      db.collection('todos').doc(id).set(todo);

      //* Since your state is immutable, you are not allowed to do like this; state.add(todo). Instead, create a new list that contains a new items and previous items
      state = [
        ...state,
        newTodo,
      ];
    } catch (error, stackTrace) {
      debugPrintStack(label: error.toString(), stackTrace: stackTrace);

      rethrow;
    }
  }

  void remove(Todo target) {
    //* The where method goes through every item of a List (state). If the Todo target's id is not the same as Todo todo's id, leave it in the new list (state), if it is the same, throw it away.
    state = state
        .where((todo) => todo.id != target.id)
        .toList(); //* Your state is immutable, so you are making a new list

    final db = FirebaseFirestore.instance;
    db.collection('todos').doc(target.id).delete();
  }

  void toggle(String id, bool completed) {
    state = [
      //* for loop. todo is every item in the list (state)
      for (final todo in state)
        if (todo.id ==
            id) //* if the id of todo in the existing list is equal to the id passed to this function, pass the same id and description to the todo, but flip completed.
          todo.copyWith(completed: completed)
        else
          todo, //* If the id passed to this functio is not equal to todo, leave it
    ];

    final db = FirebaseFirestore.instance;

    for (final todo in state) {
      if (todo.id == id) {
        Map<String, dynamic> todoMap = {
          'id': todo.id,
          'description': todo.description,
          'createdAt': todo.createdAt,
          'completed': completed,
        };
        db.collection('todos').doc(id).update(todoMap);
      }
    }
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

    final db = FirebaseFirestore.instance;

    for (final todo in state) {
      Map<String, dynamic> todoMap = {
        'id': todo.id,
        'description': description,
        'createdAt': todo.createdAt,
        'completed': todo.completed,
      };
      db.collection('todos').doc(id).update(todoMap);
    }
  }
}

//* Notifier type is TodoList, Value type is List<Todo>. TodoList.new is passed as the initial value
final todoListProvider = NotifierProvider<TodoList, List<Todo>>(
  () => TodoList(),
);
