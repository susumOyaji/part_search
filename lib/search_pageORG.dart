import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';
import './highlighted_text.dart';
//import 'dart:io';

class Memo {
  final int id;
  final String location;
  final String rack;
  final String board;
  final String container;
  final String parts;

  Memo(
      {required this.id,
      required this.location,
      required this.rack,
      required this.board,
      required this.container,
      required this.parts});

  Map<String, dynamic> toMap() {
    return {
      //'id': id,
      'Location': location,
      'Rack': rack,
      'Board': board,
      'Container': container,
      'Parts': parts,
    };
  }

  //printで見やすくするための実装
  @override
  String toString() {
    return 'Memo{id: $id, Location: $location, Rack: $rack, Board: $board,Container: $container,Parts:$parts}';
  }
} //class Memo

class SearchPageORG extends StatefulWidget {
  const SearchPageORG({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPageORG> {
  TextEditingController? controller;
  bool isCaseSensitive = false;

  List widgets = [];
  bool isLoading = false; //テーブル読み込み中の状態を保有する

  List<Memo> _dowresponce = [];
  List<Map<String, dynamic>> _singleList = [];

  bool isFirst = true;
  bool isSecond = false;
  //bool isThird = true;
  //bool isSub = true;
  String hintText = 'Scanning to  Anything-Barcode';

  String isFirstString = "";
  String isSecondString = "";

  // databaseをオープンしてインスタンス化する
  static Future<Database> get database async {
    final Future<Database> _database = openDatabase(
      // pathをデータベースに設定しています。
      // 'path'パッケージからの'join'関数を使用する事は、DBをお互い（iOS, Android）のプラットフォームに構築し、
      // pathを確保するのに良い方法です。
      join(await getDatabasesPath(),
          'memo_database5.db'), // memo_database2.dbのパスを取得する

      // Memo テーブルのデータベースを作成しています。
      // ここではSQLの解説は省きます。
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE memo(id INTEGER PRIMARY KEY AUTOINCREMENT,location TEXT, rack TEXT,board TEXT,container TEXT,parts TEXT)",
        );
      },
      version: 1,
    );
    return _database;
  }

  // catsテーブルのデータを全件取得する
  static Future<List<Memo>> selectAllMemos() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('memo');
    return List.generate(maps.length, (i) {
      return Memo(
        id: maps[i]['id'],
        location: maps[i]['location'],
        rack: maps[i]['rack'],
        board: maps[i]['board'],
        container: maps[i]['container'],
        parts: maps[i]['parts'],
      );
    });
  }

  // id=1のデータだけ取得するための関数です。
  //static Future<List<Map<String, dynamic>>> selectMemos(int id) async {
  //  final Database db = await database;
  //  return db.query('memo', where: "id = ?", whereArgs: [id], limit: 1);
  //}

  // DBからデータを一件だけ取得するための関数
  static Future<List<Map<String, dynamic>>> selectMemos(int id) async {
    final db = await database;
    return await db.query(
      'memo',
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );
  }

  // DBにデータを挿入するための関数です。
  static Future<void> insertMemo(Memo memo) async {
    final Database db = await database;
    await db.insert(
      'memo',
      memo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // DB内にあるデータを更新するための関数
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

  // DBからデータを削除するための関数
  static Future<void> deleteMemo(int id) async {
    final db = await database;
    await db.delete(
      'memo',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<Memo>> initializeMemo() async {
    List<Memo> _memoList = await selectAllMemos();

    //return Future.delayed(const Duration(seconds: 3), () {
    return _memoList;
    //"initializeDemo completed!!";
    //});
  }

  Future<List<Map<String, dynamic>>> singleMemo(int id) async {
    List<Map<String, dynamic>> _memoList1 = await selectMemos(id);

    //return Future.delayed(const Duration(seconds: 3), () {
    return _memoList1;
    //"initializeDemo completed!!";
    //});
  }

  // Stateのサブクラスを作成し、initStateをオーバーライドすると、wedgit作成時に処理を動かすことができる。
  // ここでは、初期処理としてCatsの全データを取得する。
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();

    //insertMemo(fido);
    _load();
  }

  @override
  void dispose() {
    super.dispose();
    controller!.dispose();
  }

  final List<String> searchTargets =
      List.generate(10, (index) => 'Something ${index + 1}');

  // 挿入
  //insertMemo(Memo memo);

  void already() async {
    final Database db = await database;

    //LIKE句を使いたい場合は以下のように書くことができます。
    //このように書くことで「Flutter」から始まるtextにマッチします。
    final text = '';
    final Results =
        await db.query('memo', where: 'board LIKE ?', whereArgs: ['${text}%']);

    if (Results.isEmpty) {
      print('empty');
      return;
    }

    // ここから検索処理
    String json = Results.toString();
    RegExp searchstring = RegExp(r'Location:.....');

    List<String?> searchresuit =
        searchstring.allMatches(json).map((match) => match.group(0)).toList();

    print('既に$searchresuitに登録されています。');

    print(Results);
  }

  List<String> searchResults = [];

  //query to input Deta
  void search(String query, {bool isCaseSensitive = false}) {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    //final List<Map<String, dynamic>> maps = await db.query('memo');

    if (isFirst == true) {
      // 指定した文字列(パターン)で始まるか否かを調べる。
      String q = query.substring(0, 1);
      if (q == 'a' || q == 'b' || q == 'c' || q == 'p') {
        setState(() {
          hintText = 'Second to Barcode';
          isFirstString = query;
          searchResults.clear();
          isFirst = false;
          isSecond = true;
        });
        return;
      } else {
        hintText = 'Bad! to Barcode';
        return;
      }
    }

    if (isSecond == true) {
      // 指定した文字列(パターン)で始まるか否かを調べる。
      String q = query.substring(0, 1);
      if (q == 'b' || q == 'c' || q == 'p') {
        setState(() {
          isSecondString = query;
          searchResults.clear();
          isFirst = true;
          isSecond = false;
        });
      } else {
        hintText = 'Bad! to Barcode';
        return;
      }
    }

    if (isFirstString.startsWith('a') && isSecondString.startsWith('b')) {
      hintText = 'Good 1st. to Barcode';
      var fido = Memo(
        id: 0,
        location: '001',
        rack: isFirstString,
        board: isSecondString,
        container: 'non',
        parts: 'non',
      );
      insertMemo(fido);
      //deleteMemo(0);
    }

    if (isFirstString.startsWith('b') && isSecondString.startsWith('c')) {
      hintText = 'Good 2nd. to Barcode';

      //final asmap = _memoList.asMap(); //リストをMap型に変換する。
      //final result = _memoList.contains('b'); //リストの要素に指定した要素が含まれているかを判定する。
      //asmap.containsValue("b"); //指定した値が連想配列(Map)のvalueにあるかどうかを判定する。
      print(_singleList);
      already();
    }
    if (isFirstString.startsWith('c') && isSecondString.startsWith('p')) {
      hintText = 'Good 3nd. to Barcode';
    }

    /*
    if (query.startsWith('c') && isThird == true) {
      // 指定した文字列(パターン)で始まるか否かを調べる。
      setState(() {
        isFirstString = query;
        searchResults.clear();
        isFirst = false;
        isSecond = false;
        isThird = true;
        hintText = 'Part. to Barcode';
      });
      return;
      //searcContaners.add(query);
      //container = container.toSet().toList(); //重複する要素を全て削除する
      //hitItems = searcContaners;
    }

    if (query.startsWith('p') && isThird == true) {
      // 指定した文字列(パターン)で始まるか否かを調べる。
      setState(() {
        isFirstString = query;
        searchResults.clear();
        isFirst = false;
        hintText = 'Contaner. to Barcode';
      });
      return;

      //searcParts.add(query);
      //parts = parts.toSet().toList(); //重複する要素を全て削除する
      //hitItems = searcParts;
    }
    */

    final List<String> hitItems = searchTargets.where((element) {
      if (isCaseSensitive) {
        return element.contains(query);
      }
      return element.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchResults = hitItems;
    });
  }

  // initStateで動かす処理。
  // catsテーブルに登録されている全データを取ってくる
  void _load() async {
    setState(() => isLoading = true); //テーブル読み込み前に「読み込み中」の状態にする
    _dowresponce = await initializeMemo(); ////Memosテーブルを全件読み込む
    _singleList = await singleMemo(1);
    setState(() => isLoading = false); //「読み込み済」の状態にする
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SqlApp'),
      ),
      body: isLoading //「読み込み中」だったら「グルグル」が表示される
          ? const Center(
              child: CircularProgressIndicator(), // これが「グルグル」の処理
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Case Sensitive'),
                    value: isCaseSensitive,
                    onChanged: (bool newVal) {
                      setState(() {
                        isCaseSensitive = newVal;
                      });
                      search(controller!.text, isCaseSensitive: newVal);
                    },
                  ),
                  Container(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'FirstString: ${isFirstString}   \nSecondString: ${isSecondString}'),
                    ],
                  )),
                  TextField(
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (String val) {
                      print(val);
                      search(val, isCaseSensitive: isCaseSensitive);
                      controller?.clear(); //リセット処理
                      //search(val, isCaseSensitive: isCaseSensitive);
                      //controller?.clear(); //リセット処理
                    },
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hintText,
                      enabledBorder: OutlineInputBorder(
                          //何もしていない時の挙動、見た目
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.greenAccent,
                          )),
                      focusedBorder: OutlineInputBorder(
                          //フォーカスされた時の挙動、見た目
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.amber,
                          )),
                    ),
                    onChanged: (String val) {
                      //ユーザーがデバイス上でTextFieldの値を変更した場合のみ発動される.
                      //search(val, isCaseSensitive: isCaseSensitive);
                      //controller?.clear(); //リセット処理
                    },
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _singleList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(_dowresponce.toString()),

                        //HighlightedText(
                        // wholeString: searchResults[index],
                        // highlightedString: controller!.text,
                        // isCaseSensitive: isCaseSensitive,
                        //),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
