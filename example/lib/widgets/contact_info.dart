import 'package:flutter/material.dart';

class ContactInfo extends StatelessWidget {
  const ContactInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          backgroundImage: AssetImage('assets/images/user_icon.png'),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dexter',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Online',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
