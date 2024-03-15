import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'todo.dart';

/// Some keys used for testing
final addTodoKey = UniqueKey();

/// Creates a [TodoList] and initialise it with pre-defined values.
///
/// We are using [StateNotifierProvider] here as a `List<Todo>` is a complex
/// object, with advanced business logic like how to edit a todo.
//* Notifier type is TodoList, Value type is List<Todo>. TodoList.new is passed as the initial value
final todoListProvider = NotifierProvider<TodoList, List<Todo>>(
  () => TodoList(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //? Every time some change happens to todoListProvider, this build method will rebuild. This means the entire Scaffold has to be recalculated again, which i think is redundant.
    final todos = ref.watch(todoListProvider);
    final newTodoController = useTextEditingController();

    void addItem() {
      final enteredText = newTodoController.text;

      if (enteredText.isEmpty) {
        return;
      }

      ref.read(todoListProvider.notifier).add(enteredText);
      newTodoController.clear();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    // ? Why addTodoKey is necessary here?
                    key: addTodoKey,
                    controller: newTodoController,
                    onSubmitted: (value) {
                      //* A callback function for when the user are done editing (when pressing the enter key). OnSubmitted takes String so value is type String
                      ref.read(todoListProvider.notifier).add(value);
                      newTodoController.clear();
                    },
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  width: 60,
                  height: 40,
                  child: IconButton(
                      onPressed: addItem,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      )),
                )
              ],
            ),
            //* for loop. var i = 0: the initial value. It repeats until the condition (i < todos.length) is met. i++: this increments i by 1 after each iteration
            //* spread operator is used to spread the elements of todos.
            //? Why spread operator is used? Maybe for creating a new list?
            for (var i = 0; i < todos.length; i++) ...[
              if (i > 0)
                const Divider(
                    height:
                        0), //* if i > 0 () (there is at least TWO todos, because the first index of a List is 0 and i = 1 refers to the second element in the List), divider is inserted in between
              Dismissible(
                //* Dismissible requires key parameter to identify which item should be remove. id is used for it.
                key: ValueKey(todos[i].id),
                onDismissed: (_) {
                  //* Disimiss direction isn't specified so you can swipe items away in both directions
                  ref.read(todoListProvider.notifier).remove(todos[i]);
                },
                background: Container(
                  decoration: const BoxDecoration(color: Colors.red),
                  child: const Center(
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                ),
                //* Use ProviderScope to override the behavior of a provider (_currentTodo)
                child: ProviderScope(
                  overrides: [
                    //* _currentTodo is overridden
                    _currentTodo.overrideWithValue(todos[i]),
                  ],
                  child: const TodoItem(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A provider which exposes the [Todo] displayed by a [TodoItem].
///
/// By retrieving the [Todo] through a provider instead of through its
/// constructor, this allows [TodoItem] to be instantiated using the `const` keyword.
///
/// This ensures that when we add/remove/edit todos, only what the
/// impacted widgets rebuilds, instead of the entire list of items.
//* throw is a keyword to raise an exception (an exception happens when an unexpected accident happens)
//* UnimplementedError is Thrown by operations that have not been implemented yet.
//* Provider can be used for offering a way for tests or widgets to override a value.
//* _currentTodo is used for specifying which item is currently being shown as a TodoItem
//* _currentTodo is overriden in the code above.
//? With that in mind, UnimplementedError is used for when the coder happened not to override _currentTodo?
final _currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

/// The widget that that displays the components of an individual Todo Item
class TodoItem extends HookConsumerWidget {
  const TodoItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(
        _currentTodo); //* watches _currentTodo, which is every time being shown. Not the list itself.
    //* useFocusNode is provided by flutter_hooks package.
    final itemFocusNode = useFocusNode();
    //* itemIsFocused determines if itemFocusNode has focus
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    //* This gives textField a focus
    final textFieldFocusNode = useFocusNode();

    //* Material gives you elevation like 3D visual effect
    return Material(
      color: Colors.white,
      elevation: 6,
      //* Focus widget can be used for widgets that can interact with UI. Wrapping ListTile with Focus allows ListTile to be focusable
      child: Focus(
        //* useFocusNode creates a FocusNode that can be disposed automatically. This focusNode manages CheckBox and TextField. This allows you to give them focus. FocusNode is a long-lived object so it needs to be disposed
        focusNode: itemFocusNode,
        //* if the widget's focus node gains focus, returns true. if it loses focus, returns false. If the user tapped a ListTile item, returns TWO trues because ListTile item and TextField both have FocusNode. When the user tapped outside of ListTile, ListTile loses its focus, returning false
        onFocusChange: (focused) {
          //* if focused is true (the user focused a todo item (when the user tapped it)), textEditingController.text which entered by the user is todo.description which was previously entered by the user
          if (focused) {
            textEditingController.text = todo.description;
          } else {
            // Commit changes only when the textfield is unfocused, for performance
            //* The above means when the user are done with editing by unfocusing the TextField (pressing enter key or tapping outside of ListTile), commit changes
            ref
                .read(todoListProvider.notifier)
                .edit(id: todo.id, description: textEditingController.text);
          }
        },
        child: ListTile(
          onTap: () {
            //* Upon tapped, give focus to an item of ListTile. TextField is nested into ListTile, so in FocusTree, you have to first give focus to the ancestor, which in this case, is ListTile
            itemFocusNode.requestFocus();
            //* Upon tapped, give focus to TextField. Without this, TextField cannot get focus upon tapped, meaning that the user has to tap a ListTile item twice to edit TextField
            textFieldFocusNode.requestFocus();
          },
          trailing: Checkbox(
            value: todo.completed,
            onChanged: (value) =>
                ref.read(todoListProvider.notifier).toggle(todo.id),
          ),
          //* If itemIsFocused is true (the user taps a ListTile item), take TextField; otherwise, take Text() as it is
          title: itemIsFocused
              ? TextField(
                  autofocus: true,
                  //* Pass the FocusNode to this TextField
                  focusNode: textFieldFocusNode,
                  controller: textEditingController,
                )
              : Text(todo.description),
          subtitle: Text(todo.createdAt.toString()),
        ),
      ),
    );
  }
}

//* This function takes FocusNode node as its argument and returns a boolean value
bool useIsFocused(FocusNode node) {
  //* useState returns ValueNotifier and ValueNotifer extends ChangeNotifier. ChangeNotifier holds a single value and if the value changes, it notifies its listeners
  //* useState takes a type generic (initial data), which is, in this case, boolean value (node.hasFocus)
  //* The initial value of isFocused is set to the initial state of node.hasFocus
  //* The useState hooks returs a mutable state object that can be updated and triggers a rebuild of the widget when its value changes.
  final isFocused = useState(node.hasFocus);

  //* useEffect performs side effects in a widget (In this case its not related to any specific widgets).  Side effects are operations that don't directly affect the rendering of the widget but may have other effects, such as interacting with external APIs, subscribing to streams, or setting up event listeners.
  useEffect(
    //* The first argument is a side effect you want to perform. This function will run when the widget is first built and every time the dependencies change (FocusNode node, in this case)
    () {
      //* The listener function is defined here. This updates isFocused which is ValueNotifer based on the focus state of FocusNode node. If FocusNode node has focus, isFocused is set to true
      void listener() {
        isFocused.value = node.hasFocus;
      }

      //* You are telling Flutter to execut the listener function every time the focus state of the FocusNode changes. addLister and removeLister functions are Listenable. istenable is an interface that provides those two methods. There are classes that implement this Listenable class, such as ChangeNotifier and ValueNotifier. TextEditingController is actually ValueNotifier
      node.addListener(listener);
      //* This is a cleanup logic. This method removes the previously attached listener function from the FocusNode. It's important to remove listeners when they are no longer needed to prevent memory leaks and unnecessary resource usage.
      return () => node.removeListener(listener);
    },
    //* The dependencies in the useEffect hook determine when the effect function is called. The only dependency is node so  the effect function will be called again whenever the FocusNode changes.
    [node],
  );
  //* By returning isFocused.value, useIsFocused can return the current state of FocusNode node with a boolean value
  return isFocused.value;
}
