import 'package:flutter/material.dart';

class ViewersListModel extends ChangeNotifier {
  List<String> originalBroadcasterList = [];
  List<String> originalModeratorList = [];
  List<String> originalVipList = [];
  List<String> originalViewerList = [];

  List<String> filteredBroadcasterList = [];
  List<String> filteredModeratorList = [];
  List<String> filteredVipList = [];
  List<String> filteredViewerList = [];

  init(List<String> broadcasterList, List<String> moderatorList,
      List<String> vipList, List<String> viewerList) {
    // originalBroadcasterList = [...broadcasterList];
    // originalModeratorList = [...moderatorList];
    // originalVipList = [...vipList];
    // originalViewerList = [...viewerList];

    // filteredBroadcasterList = [...broadcasterList];
    // filteredModeratorList = [...moderatorList];
    // filteredVipList = [...vipList];
    // filteredViewerList = [...viewerList];

    Future.wait([
      copyList(broadcasterList)
          .then((value) => originalBroadcasterList = value),
      copyList(moderatorList).then((value) => originalModeratorList = value),
      copyList(vipList).then((value) => originalVipList = value),
      copyList(viewerList).then((value) => originalViewerList = value),
      copyList(broadcasterList)
          .then((value) => filteredBroadcasterList = value),
      copyList(moderatorList).then((value) => filteredModeratorList = value),
      copyList(vipList).then((value) => filteredVipList = value),
      copyList(viewerList).then((value) => filteredViewerList = value),
    ]);
  }

  // parallelFiltered(String searchBarText) async {
  // }

  Future<List<String>> filterList(
      List<String> list, String searchBarText) async {
    return list
        .where(((String element) => element.contains(searchBarText)))
        .toList();
  }

  Future<List<String>> copyList(List<String> list) async {
    return [...list];
  }

  filteredByText(String searchBarText) {
    if (searchBarText.isEmpty) {
      Future.wait([
        copyList(originalBroadcasterList)
            .then((value) => filteredBroadcasterList = value),
        copyList(originalModeratorList)
            .then((value) => filteredModeratorList = value),
        copyList(originalVipList).then((value) => filteredVipList = value),
        copyList(originalViewerList)
            .then((value) => filteredViewerList = value),
      ]);
    } else {
      Future.wait([
        filterList(originalBroadcasterList, searchBarText)
            .then((value) => filteredBroadcasterList = value),
        filterList(originalModeratorList, searchBarText)
            .then((value) => filteredModeratorList = value),
        filterList(originalVipList, searchBarText)
            .then((value) => filteredVipList = value),
        filterList(originalViewerList, searchBarText)
            .then((value) => filteredViewerList = value),
      ]);

      // filteredBroadcasterList = originalBroadcasterList
      //     .where(((String element) => element.contains(searchBarText)))
      //     .toList();
      // filteredModeratorList = originalModeratorList
      //     .where(((String element) => element.contains(searchBarText)))
      //     .toList();
      // filteredVipList = originalVipList
      //     .where(((String element) => element.contains(searchBarText)))
      //     .toList();
      // filteredViewerList = originalViewerList
      //     .where(((String element) => element.contains(searchBarText)))
      //     .toList();
    }
    notifyListeners();
  }
}
