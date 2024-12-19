import 'package:box_pusher/box_pusher_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// HR
class CustomHorizonBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    return const Divider(
      height: 10,
      thickness: 0.5,
    );
  }
}

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
              builders: {
                'hhrr': CustomHorizonBuilder(),
              },
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
