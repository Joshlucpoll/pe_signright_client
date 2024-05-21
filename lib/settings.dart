import 'package:flutter/cupertino.dart';
import 'package:collection/collection.dart';

import 'data/wordlist.dart' as word_list;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // navigationBar: CupertinoSliverNavigationBar(

      //   middle: const Text('Settings', style: TextStyle(fontSize: 64)),
      // ),
      child: CustomScrollView(
        slivers: <Widget>[
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          SliverFillRemaining(
            child: CupertinoListSection.insetGrouped(
              children: <CupertinoListTile>[
                CupertinoListTile(
                  title: const Text('Word List'),
                  leading: Icon(CupertinoIcons.square_list),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (BuildContext context) {
                        return const WordList();
                      },
                    ),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('Push to master'),
                  leading: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: CupertinoColors.systemRed,
                  ),
                  additionalInfo: const Text('Not available'),
                ),
                CupertinoListTile(
                  title: const Text('View last commit'),
                  leading: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: CupertinoColors.activeOrange,
                  ),
                  additionalInfo: const Text('12 days ago'),
                  trailing: const CupertinoListTileChevron(),
                  // onTap: () => Navigator.of(context).push(
                  //   CupertinoPageRoute<void>(
                  //     builder: (BuildContext context) {
                  //       return const _SecondPage(text: 'Last commit');
                  //     },
                  //   ),
                  // ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum WordListSegment {
  oneHundred,
  threeHundred,
  oneThousand,
  twoThousand,
}

List<int> _wordListCount = <int>[100, 300, 1000, 2000];

class WordList extends StatefulWidget {
  const WordList({super.key});

  @override
  State<WordList> createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  WordListSegment _selectedSegment = WordListSegment.oneHundred;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSlidingSegmentedControl<WordListSegment>(
          groupValue: _selectedSegment,
          children: const <WordListSegment, Widget>{
            WordListSegment.oneHundred: Text('ASL-100'),
            WordListSegment.threeHundred: Text('ASL-300'),
            WordListSegment.oneThousand: Text('ASL-1000'),
            WordListSegment.twoThousand: Text('ASL-2000'),
          },
          onValueChanged: (WordListSegment? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSegment = newValue;
              });
            }
          },
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 44.0),
          child: CupertinoListSection.insetGrouped(
            header:
                Text("Words for ASL-${_wordListCount[_selectedSegment.index]}"),
            children: word_list.words
                .take(_wordListCount[_selectedSegment.index])
                .mapIndexed(
                  (index, word) => CupertinoListTile(
                    title: Text(word),
                    leading: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                          fontSize: 11, color: CupertinoColors.systemGrey),
                    ),
                    // trailing: const CupertinoListTileChevron(),
                    // onTap: () {
                    //   // Handle tile tap
                    // },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
