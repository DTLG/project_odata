import 'package:flutter/material.dart';

class CommmonCard extends StatelessWidget {
  const CommmonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
        // final themeManager = AdaptiveTheme.of(context);

    return 
    Card(
      
  elevation: 0,
  // color: 
  // themeManager.mode.isLight?
  //  Colors.grey[200]:AppColors.lightTableElementDarkTheme,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  clipBehavior: Clip.antiAlias,
  margin: const EdgeInsets.all(5),
  child: child,);
    
   
  }
}
