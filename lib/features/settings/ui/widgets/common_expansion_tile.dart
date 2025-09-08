import 'package:flutter/material.dart';

class CommonExpansionTile extends StatelessWidget {
  const CommonExpansionTile(
      {super.key, required this.children, required this.title});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title),

         children: children
        ));
  }
}
