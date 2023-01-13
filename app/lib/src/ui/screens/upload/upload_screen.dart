import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:postapic/src/data/blocs/posts/posts_cubit.dart';
import 'package:postapic/src/data/repositories/upload_repository.dart';

class UploadParams {
  const UploadParams({required this.title});

  final String title;
}

typedef UploadCallback = Future<void> Function(UploadParams params);

class UploadScreen extends StatelessWidget {
  UploadScreen({
    super.key,
    required this.onUpload,
    required this.image,
  });

  final UploadCallback onUpload;
  final ImageProvider image;

  final _titleController = TextEditingController();

  static Route<void> route({
    required UploadCallback onUpload,
    required ImageProvider image,
  }) {
    return MaterialPageRoute(
      builder: (context) => UploadScreen(onUpload: onUpload, image: image),
      settings: const RouteSettings(name: '/settings'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        actions: [
          _UploadButton(titleController: _titleController, onUpload: onUpload),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              hintText: 'Caption',
              border: InputBorder.none,
            ),
          ),
          Expanded(
            child: Image(
              image: image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatefulWidget {
  const _UploadButton({
    required this.titleController,
    required this.onUpload,
  });

  final TextEditingController titleController;
  final UploadCallback onUpload;

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
  var _loading = false;

  Future<void> _share() async {
    setState(() {
      _loading = true;
    });
    try {
      await widget.onUpload(UploadParams(title: widget.titleController.text));
      if (mounted) {
        Navigator.of(context).pop();
        BlocProvider.of<PostsCubit>(context, listen: false).reloadAll();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.titleController,
      builder: (context, value, child) => TextButton(
        onPressed: value.text.isEmpty ? null : _share,
        child:
            _loading ? const CupertinoActivityIndicator() : const Text('Share'),
      ),
    );
  }
}

class UploadJourney {
  UploadJourney(this.context, this.uploadRepository);

  final BuildContext context;
  final UploadRepository uploadRepository;

  final _imagePicker = ImagePicker();

  File? _file;

  Future<void> startUpload() async {
    final navigator = Navigator.of(context);

    final file = await _selectFile();
    if (file == null) {
      return;
    }

    _file = File(file.path);

    await navigator.push(UploadScreen.route(
      onUpload: _upload,
      image: FileImage(_file!),
    ));
  }

  Future<XFile?> _selectFile() async {
    final source = await showCupertinoDialog<ImageSource?>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choose image source'),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
    if (source == null) {
      return null;
    }

    return _imagePicker.pickImage(source: source);
  }

  Future<void> _upload(UploadParams params) {
    return uploadRepository.upload(title: params.title, picture: _file!);
  }
}
