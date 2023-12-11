import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:tvbox_controller/simple_models.dart';

import 'x_http_utils.dart';


class ApiUtils{
  static Future<List<LiveChannelItem>> getLiveChannelItemS() async {
    final request = await XHttpUtils.getForFullResponse(
        "");
    String reply = await request.transform(utf8.decoder).join();
    final list = reply.trim().split('\n').mapIndexed((index, e) {
      final item = e.split(",");
      return LiveChannelItem(item.first, [item.last], index: index);
    }).toList();
    return list;
  }
}