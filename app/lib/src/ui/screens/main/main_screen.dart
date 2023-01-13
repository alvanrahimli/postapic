import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:postapic/src/data/blocs/auth/auth_cubit.dart';
import 'package:postapic/src/data/repositories/upload_repository.dart';
import 'package:postapic/src/ui/screens/feed/feed_screen.dart';
import 'package:postapic/src/ui/screens/profile/profile_screen.dart';
import 'package:postapic/src/ui/screens/upload/upload_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _initiateUpload(context),
        child: const Icon(CupertinoIcons.plus),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (next) {
          setState(() {
            _currentPage = next;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled),
            label: 'Profile',
          ),
        ],
      ),
      body: const [
        FeedScreen(),
        ProfileScreen(),
      ][_currentPage],
    );
  }

  void _initiateUpload(BuildContext context) {
    const dialogTitle = Text('Oopsie');
    const dialogContent = Text(
      'You need to be logged in before posting a pic!',
    );

    final authState = context.read<AuthCubit>().state;
    if (authState == null) {
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: dialogTitle,
            content: dialogContent,
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }

      if (Platform.isAndroid) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: dialogTitle,
            content: dialogContent,
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }

      return;
    }

    UploadJourney(context, GetIt.instance.get<UploadRepository>())
        .startUpload();
  }
}
