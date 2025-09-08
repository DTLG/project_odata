import 'package:flutter/material.dart';

class SettingsElement extends StatelessWidget {
  const SettingsElement(
      {super.key,
      required this.title,
      required this.controller,
      required this.onChanged,
      this.hintText = '',
      this.divider = true});

  final String title;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool divider;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(title), SizedBox(
                width: 200,
                height: 40,
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.end,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none, hintText: hintText),
                )),
            ],
          ),
        ),
       
        divider
            ? const Divider(
                color: Color.fromARGB(255, 188, 188, 188),
                indent: 15,
                endIndent: 15,
              )
            : const SizedBox()
      ],
    );
  }
}
