import 'package:flutter/material.dart';

class custsearchBar extends StatefulWidget {
  const custsearchBar({super.key});

  @override
  State<custsearchBar> createState() => _custsearchBarState();
}

class _custsearchBarState extends State<custsearchBar> {
  String? selected;
  final List<String>_suggestion =[
    "1",
    "2",
    "3"
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
      child: Autocomplete(
        fieldViewBuilder: ((context,texteditingcontroller,focusnode,onfieldsubmitted){
          return TextFormField(
            controller: texteditingcontroller,
            focusNode: focusnode,
            style: const TextStyle(
              color: Colors.amber),
              onFieldSubmitted: (value) => onfieldsubmitted,
              decoration: const InputDecoration(
                hintText: "Search and see suggestion",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                )
              ),
          );
        }
      ),
      optionsBuilder: (TextEditingValue textEditingValue) async{
        if(textEditingValue.text == ''){
          return const Iterable<String>.empty();
        }
        final List<String>result = [];
        for (var e in _suggestion){
          if(e
          .toString()
          .toLowerCase()
          .contains(textEditingValue.text.toLowerCase())){
            result.add(e.toString());
          }
        } 
        return result;
      },
      onSelected: (selection) {
        
      },
      ),
      ),
    );
  }
}