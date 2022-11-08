import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';

class Memo {
  final int id;
  final String text;

  Memo({required this.id, required this.text});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
    };
  }

  @override
  String toString() {
    return 'Memo{id: $id, text: $text}';
  }

  static Future<Database> get database async {
    final Future<Database> _database = openDatabase(
      join(await getDatabasesPath(), 'memo_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE memo(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT)",
        );
      },
      version: 1,
    );
    return _database;
  }

  static Future<void> insertMemo(Memo memo) async {
    final Database db = await database;
    await db.insert(
      'memo',
      memo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Memo>> getMemos() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('memo');
    return List.generate(maps.length, (i) {
      return Memo(
        id: maps[i]['id'],
        text: maps[i]['text'],
      );
    });
  }

  static Future<void> updateMemo(Memo memo) async {
    final db = await database;
    await db.update(
      'memo',
      memo.toMap(),
      where: "id = ?",
      whereArgs: [memo.id],
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  static Future<void> deleteMemo(int id) async {
    final db = await database;
    await db.delete(
      'memo',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo SQL',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MySqlPage(),
    );
  }
}

class MySqlPage extends StatefulWidget {
  const MySqlPage({super.key});
  @override
  _MySqlPageState createState() => _MySqlPageState();
}

class _MySqlPageState extends State<MySqlPage> {
  List<Memo> _memoList = [];
  final myController = TextEditingController();
  final upDateController = TextEditingController();
  var _selectedvalue;
  int searchResultsIndex = 0;
  bool searchResultsValue = false;

  Future<void> initializeDemo() async {
    _memoList = await Memo.getMemos();

    var res = search('a001');
    print('RES$res');
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  dynamic search(String query) {
    int index = 0;
    if (query.isEmpty) {
      setState(() {
        //searchResultsValue = false; //searchResults.clear();
      });
      return 'isEmpty';
    }

    for (index; index < _memoList.length; index++) {
      final fruits = _memoList[index].toMap();

      bool resultkey = fruits.containsKey('id');
      bool resultValue = fruits.containsValue(query);

      print('toMap${fruits}');
      print(resultkey);
      print(resultValue);

      if (resultValue == true) {
        return index;
      } else {
        return 'nonMatch';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモアプリ'),
      ),
      body: Container(
        padding: const EdgeInsets.all(32),
        child: FutureBuilder(
          future: initializeDemo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // 非同期処理未完了 = 通信中
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              itemCount: _memoList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: Text(
                      'ID ${_memoList[index].id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text('${_memoList[index].text}'),
                    trailing: SizedBox(
                      width: 76,
                      height: 25,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Memo.deleteMemo(_memoList[index].id);
                          final List<Memo> memos = await Memo.getMemos();
                          setState(() {
                            _memoList = memos;
                          });
                        },
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          '削除',
                          style: TextStyle(fontSize: 11),
                        ),
                        //color: Colors.red,
                        //textColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        verticalDirection: VerticalDirection.up,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Text("新規メモ作成"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('なんでも入力'),
                            TextField(controller: myController),
                            ElevatedButton(
                              child: const Text('保存'),
                              onPressed: () async {
                                Memo _memo = Memo(
                                    id: _memoList.length,
                                    text: myController.text);
                                await Memo.insertMemo(_memo);
                                final List<Memo> memos = await Memo.getMemos();
                                setState(() {
                                  _memoList = memos;
                                  _selectedvalue = null;
                                });
                                myController.clear();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ));
            },
          ),
          const SizedBox(height: 20),
          FloatingActionButton(
              child: Icon(Icons.update),
              backgroundColor: Colors.amberAccent,
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('IDを選択して更新してね'),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: DropdownButton(
                                        hint: Text("ID"),
                                        value: _selectedvalue,
                                        onChanged: (newValue) {
                                          setState(() {
                                            _selectedvalue = newValue;
                                            print(newValue);
                                          });
                                        },
                                        items: _memoList.map((entry) {
                                          return DropdownMenuItem(
                                              value: entry.id,
                                              child: Text(entry.id.toString()));
                                        }).toList(),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 3,
                                      child: TextField(
                                          controller: upDateController),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  child: const Text('更新'),
                                  onPressed: () async {
                                    Memo updateMemo = Memo(
                                        id: _selectedvalue,
                                        text: upDateController.text);
                                    await Memo.updateMemo(updateMemo);
                                    final List<Memo> memos =
                                        await Memo.getMemos();
                                    super.setState(() {
                                      _memoList = memos;
                                    });
                                    upDateController.clear();
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    });
              }),
        ],
      ),
    );
  }
}
