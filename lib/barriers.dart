import 'package:flutter/material.dart';
class Barriers extends StatelessWidget {

   final size;
  const Barriers({super.key, this.size});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: size,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 25, 124, 41),
        border: Border.all(width: 5,color: const Color.fromARGB(255, 19, 82, 19)),
        borderRadius: BorderRadius.circular(10)
      ),
    );
  }
}