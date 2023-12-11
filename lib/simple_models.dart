class LiveChannelItem {
  final String name;
  final List<String> urls;
  int epginfoIndex;
  int index;

  LiveChannelItem(this.name, this.urls, {this.epginfoIndex = 0, this.index = 0});
}