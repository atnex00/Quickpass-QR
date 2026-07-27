import 'package:flutter/material.dart';
import '../config/theme.dart';

class LoadingIndicator extends StatelessWidget {

  const LoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.primaryBlue),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: context.neutralGray,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
