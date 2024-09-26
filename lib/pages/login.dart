import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todoer/blocs/auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    var authCubit = context.read<AuthCubit>();
    return Center(
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Яндекс'),
            onPressed: () => authCubit.startLogin(),
          )
        ],
      ),
    );
  }
}
