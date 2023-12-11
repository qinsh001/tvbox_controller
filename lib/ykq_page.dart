import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tvbox_controller/api_utils.dart';

import 'app_utils.dart';
import 'delay_function.dart';
import 'local_key_s.dart';
import 'simple_models.dart';
import 'sp_utils.dart';
import 'x_http_utils.dart';

class YkqPage extends StatefulWidget {
  const YkqPage({Key? key}) : super(key: key);

  @override
  State<YkqPage> createState() => _YkqPageState();
}

class _YkqPageState extends State<YkqPage> {
  late TextEditingController textController = TextEditingController();
  late TextEditingController textController2 = TextEditingController();

  late final items = [
    ("Up", "up"),
    ("Down", "down"),
    ("Play", "play"),
    ("Pause", "pause"),
    ("Close", "close"),
    ("确定", "changeItem"),
  ];

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    textController.text = SpUtil.getString(LocalKeyS.urlKey) ?? "";
    textController2.text = "${(SpUtil.getInt(LocalKeyS.itemKey)??0)+1}";
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("遥控器"),
        actions: [
          TextButton(
              onPressed: () {
                if (textController.text.isEmpty) {
                  AppUtils.showSnackBar(context, "请输入Tv上面的地址");
                  return;
                }
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return ItemsPage(address: textController.text);
                }));
              },
              child: const Text("节目列表"))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: "请输入Tv上面的地址",
              ),
              controller: textController,
            ),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: "请输入节目数字",
              ),
              controller: textController2,
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final item = items[index];
                  return ElevatedButton(
                      onPressed: () async {
                        if (textController.text.isEmpty) {
                          AppUtils.showSnackBar(context, "请输入Tv上面的地址");
                          return;
                        }
                        if (SpUtil.getString(LocalKeyS.urlKey) !=
                            textController.text) {
                          await SpUtil.putString(
                              LocalKeyS.urlKey, textController.text);
                        }
                        print(
                            "http://${textController.text}/action?type=${item.$2}");
                        if (item.$1 == "ChangeItem") {
                          if (textController2.text.isEmpty && context.mounted) {
                            AppUtils.showSnackBar(context, "请输入节目编号");
                            return;
                          }
                        }
                        XHttpUtils.getForString(
                                "http://${textController.text}/action?type=${item.$2}&content=${textController2.text}")
                            .then((value) {
                          print(value);
                        });
                      },
                      child: Text(item.$1));
                },
                itemCount: items.length,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ItemsPage extends StatefulWidget {
  final String address;

  const ItemsPage({super.key, required this.address});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  int currentIndex = 0;
  final ItemScrollController itemScrollController = ItemScrollController();
  DelayFunction function2 = DelayFunction();
  Completer completer = Completer();
  @override
  void initState() {
    super.initState();
    currentIndex = (SpUtil.getInt(LocalKeyS.itemKey) ?? 0)-1;
    if (currentIndex > 0) {
      completer.future.then((value){
        itemScrollController.scrollTo(
            index: currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("节目列表"),
      ),
      body: Center(
        child: FutureBuilder(
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data == null) {
              return const Center(
                child: Text("Error..."),
              );
            }
            final items = snapshot.data as List<LiveChannelItem>;
            completer.complete();
            print(items.length);
            return StatefulBuilder(builder: (context, setState) {
              return ScrollablePositionedList.builder(
                itemScrollController: itemScrollController,
                itemBuilder: (BuildContext context, int index) {
                  final item = items[index];
                  return ListTile(
                    dense: true,
                    textColor:
                        currentIndex == index ? Colors.red : Colors.black,
                    title: Text("${index + 1}-${item.name}"),
                    onTap: () async {
                      if (currentIndex != index) {
                        setState(() {
                          currentIndex = index;
                        });
                        function2.delayFunc(() {
                          XHttpUtils.getForString(
                                  "http://${widget.address}/action?type=changeItem&content=${currentIndex+1}")
                              .then((value) {
                            print(value);
                          });
                        }, milliseconds: 100);
                        await SpUtil.putInt(LocalKeyS.itemKey, currentIndex+1);
                      }
                    },
                  );
                },
                itemCount: items.length,
              );
            });
          },
          future: ApiUtils.getLiveChannelItemS(),
        ),
      ),
    );
  }
}
