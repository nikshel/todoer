import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:url_launcher/link.dart';

final dio = Dio(BaseOptions(
  responseType: ResponseType.json,
  receiveTimeout: const Duration(seconds: 1),
));
final releasesUri = Uri.parse('https://github.com/nikshel/todoer/releases');

class UpdateChecker extends StatefulWidget {
  final String currentTag;

  const UpdateChecker({super.key, required this.currentTag});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  late Future<String?> _checkUpdateResult;

  @override
  void initState() {
    super.initState();
    _checkUpdateResult = _getUpdate();
  }

  Future<String?> _getUpdate() async {
    var response = await dio.get(
      'https://api.github.com/repos/nikshel/todoer/releases/latest',
      options: Options(
        responseType: ResponseType.json,
        receiveTimeout: const Duration(seconds: 1),
      ),
    );

    var tag = response.data['tag_name'];
    return tag == widget.currentTag ? null : tag;
  }

  _showUpdateInfo(String newTag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Доступна новая версия: v$newTag'),
        content: Row(
          children: [
            const Text('Список релизов: '),
            Link(
              uri: releasesUri,
              builder: (BuildContext context, FollowLink? followLink) =>
                  InkWell(
                onTap: followLink,
                child: Text(releasesUri.toString(),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    )),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка поиска обновления'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkUpdateResult,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return IconButton(
            icon: const Icon(Icons.get_app),
            onPressed: () => _showUpdateInfo(snapshot.data!),
          );
        }
        if (snapshot.hasError) {
          return IconButton(
            icon: const Icon(Icons.warning),
            onPressed: () => _showError(snapshot.error.toString()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
