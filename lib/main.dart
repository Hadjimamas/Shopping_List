import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_list/checkout.dart';
import 'package:shopping_list/suggestions.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Shopping List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// Possible Actions in PopUpMenu
enum MenuActions { clearSuggestions }

class _MyHomePageState extends State<MyHomePage> {
  List<String> _items = [];
  List<String> _completedItems = [];

  final Suggestions _suggestions = Suggestions();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _items = prefs.getStringList("items") ?? [];
      _completedItems = prefs.getStringList("completedItems") ?? [];
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("items", _items);
    prefs.setStringList("completedItems", _completedItems);
  }

  TextEditingController inputController = TextEditingController();

  void _addItem() {
    String item = inputController.text;
    if (item.isNotEmpty) {
      setState(() {
        _items.add(item);
        _suggestions.add(item);

        // Reset input
        inputController.text = "";
      });
      _saveData();
    } else {
      Fluttertoast.showToast(
        msg: "Add some text to add new item.",
      );
    }
  }

  void _completeItem(int index) {
    setState(() {
      _completedItems.insert(0, _items.removeAt(index));
    });
    _saveData();
  }

  void _uncompletedItem(int index) {
    setState(() {
      _items.add(_completedItems.removeAt(index));
    });
    _saveData();
  }

  void _clearCompleted() {
    if (_completedItems.isNotEmpty) {
      setState(() {
        _completedItems.clear();
      });
      _saveData();
    } else {
      Fluttertoast.showToast(
        msg: "Select item(s) to delete",
      );
    }
  }

  void _balancePage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) => const CheckOut()

          /*{return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'This is your second page',
                  ),
                ],
              ),
            ),
          );
        },*/
          ),
    );
  }

  Widget _buildTodoList() {
    return ListView.builder(
      itemCount: _items.length + _completedItems.length,
      itemBuilder: (context, index) {
        if (index < _items.length) {
          return _buildListItem(index, _items[index]);
        } else {
          int completedIndex = index - _items.length;
          return _buildCompletedListItem(
              completedIndex, _completedItems[completedIndex]);
        }
      },
    );
  }

  // Build a single todo item
  Widget _buildListItem(int itemIndex, String todoText) {
    return ListTile(
        title: Text(todoText), onTap: () => _completeItem(itemIndex));
  }

  // Build a single completed todo item
  Widget _buildCompletedListItem(int itemIndex, String todoText) {
    return ListTile(
      title: Text(
        todoText,
        style: const TextStyle(
            color: Colors.redAccent, decoration: TextDecoration.lineThrough),
      ),
      onTap: () => _uncompletedItem(itemIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          onPressed: _balancePage,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _clearCompleted,
        ),
        PopupMenuButton<MenuActions>(
          onSelected: (MenuActions action) {
            switch (action) {
              case MenuActions.clearSuggestions:
                _suggestions.clear();
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<MenuActions>(
                child: Text("Clear Suggestions"),
                value: MenuActions.clearSuggestions,
              ),
            ];
          },
        ),
      ]),
      body: Stack(
        children: <Widget>[
          Container(
            child: _buildTodoList(),
            padding: const EdgeInsets.only(bottom: 60),
          ),
          Positioned(
            bottom: 0.0,
            width: MediaQuery.of(context).size.width, // width 100%
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x80000000),
                    offset: Offset(0.0, 6.0),
                    blurRadius: 20.0,
                  ),
                ],
              ),
              //decoration: InputDecoration(
              //         prefixIcon: prefixIcon??Icon(Icons.done),
              //       ),
              child: TypeAheadField(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: inputController,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (dynamic x) => _addItem(),
                  autofocus: true,
                  focusNode: _keyboardFocusNode,
                  decoration: InputDecoration(
                    labelText: "Product",
                    border: const OutlineInputBorder(),
                    hintText: "Enter Product",
                    suffixIcon: IconButton(
                      onPressed: _addItem,
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                direction: AxisDirection.up,
                hideOnEmpty: true,
                suggestionsCallback: (pattern) {
                  if (pattern.isNotEmpty) {
                    return _suggestions.get(pattern);
                  } else {
                    return [];
                  }
                },
                debounceDuration: const Duration(milliseconds: 100),
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.toString()),
                  );
                },
                transitionBuilder:
                    (context, suggestionsBox, animationController) =>
                        suggestionsBox,
                // no animation
                onSuggestionSelected: (suggestion) {
                  inputController.text = suggestion.toString();
                  _addItem();
                  if (!_keyboardFocusNode.hasFocus) {
                    FocusScope.of(context).requestFocus(_keyboardFocusNode);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
