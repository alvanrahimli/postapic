import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postapic/src/data/blocs/auth/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthCubit, AuthenticationState?>(
        builder: _buildBody,
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthenticationState? state) {
    final authCubit = context.read<AuthCubit>();

    return Column(
      children: [
        if (state != null) ...[
          ListTile(
            title: Text('@${state.user.userName}'),
            enabled: false,
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: authCubit.logout,
          ),
        ] else
          const LoginForm(),
      ],
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: usernameController,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
        ),
        const SizedBox(height: 15),
        ListTile(
          title: const Text('Login'),
          onTap: () => authCubit.login(
            username: usernameController.text,
            password: passwordController.text,
          ),
        ),
      ],
    );
  }
}
