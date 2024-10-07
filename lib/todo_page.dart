import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class TodoItem {
  String task;
  DateTime dueDate;

  TodoItem({required this.task, required this.dueDate});

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  // Convert Map back to TodoItem
  static TodoItem fromMap(Map<String, dynamic> map) {
    return TodoItem(
      task: map['task'],
      dueDate: DateTime.parse(map['dueDate']),
    );
  }
}

class _TodoPageState extends State<TodoPage> {
  List<TodoItem> _todoList = [];
  final TextEditingController _textController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  Future<void> _loadTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? savedTodos = prefs.getStringList("todos");
      if (savedTodos != null) {
        _todoList = savedTodos
            .map((item) => TodoItem.fromMap(json.decode(item)))
            .toList();
      }
    });
  }

  Future<void> _saveTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todoStrings =
        _todoList.map((item) => json.encode(item.toMap())).toList();
    prefs.setStringList('todos', todoStrings);
  }

  void _removeToDoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
      _saveTodoList();
    });
  }

  void _showAddToDoDialog() {
    _textController.clear();
    _selectedDate = null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah To Do Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'To Do Item Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _pickDateTime,
                child: Text(
                  _selectedDate == null
                      ? 'Atur Tanggal dan Waktu'
                      : 'Due: ${_selectedDate.toString()}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_textController.text.isNotEmpty && _selectedDate != null) {
                  setState(() {
                    _todoList.add(TodoItem(
                      task: _textController.text,
                      dueDate: _selectedDate!,
                    ));
                    _saveTodoList();
                  });
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tambah'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.green[500],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'To - Do List',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${_todoList.length}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(0),
                        topLeft: Radius.circular(0),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: _todoList.length,
                      itemBuilder: (context, index) {
                        TodoItem todo = _todoList[index];
                        return Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${index + 1}. ${capitalize(todo.task)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Text(
                                '${todo.dueDate.day}/${todo.dueDate.month}/${todo.dueDate.year} ${todo.dueDate.hour}:${todo.dueDate.minute}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _editTodoItem(index),
                                    icon: const Icon(Icons.edit,
                                        color: Colors.green),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeToDoItem(index),
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToDoDialog,
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  void _editTodoItem(int index) {}
}
