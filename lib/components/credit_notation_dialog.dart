import 'package:push_and_merge/box_pusher_game.dart';
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

class CreditNotationDialog extends StatefulWidget {
  final BoxPusherGame game;

  const CreditNotationDialog({
    required this.game,
    Key? key,
  }) : super(key: key);

  @override
  CreditNotationDialogState createState() => CreditNotationDialogState();
}

class CreditNotationDialogState extends State<CreditNotationDialog> {
  String creditNotation = '';

  CreditNotationDialogState() {
    _loadContent();
  }

  void _loadContent() async {
    rootBundle.loadString('assets/texts/credit.md').then((value) => {
          setState(() {
            creditNotation = value;
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
              data: creditNotation,
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
