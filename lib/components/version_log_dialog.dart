import 'package:box_pusher/box_pusher_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class VersionLogDialog extends StatefulWidget {
  final BoxPusherGame game;

  const VersionLogDialog({
    required this.game,
    Key? key,
  }) : super(key: key);

  @override
  VersionLogDialogState createState() => VersionLogDialogState();
}

class VersionLogDialogState extends State<VersionLogDialog> {
  String versionLog = '';

  VersionLogDialogState() {
    _loadContent();
  }

  void _loadContent() async {
    rootBundle.loadString('assets/texts/version_log.md').then((value) => {
          setState(() {
            versionLog = value;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            MarkdownBody(
              data: versionLog,
              listItemCrossAxisAlignment:
                  MarkdownListItemCrossAxisAlignment.start,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            widget.game.popSeq();
          },
        ),
      ],
    );
  }
}
