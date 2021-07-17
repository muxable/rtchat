import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/quick_links.dart';

void main(){
  test("Quick Link Source Test", (){
    var source1 = QuickLinkSource("home", "home", Uri.http("example.org", "/path", { "q" : "dart" }));
    var source2 = QuickLinkSource("analytics", "analytics", Uri.http("example.org", "/path", { "q" : "dart" }));
    var source3 = QuickLinkSource("home", "home", Uri.http("example2.org", "/path", { "q" : "dart" }));

    assert(source1 == source2);
    assert(source1 != source3);

    var sourceJson = source1.toJson();
    assert(sourceJson["name"] != null);
    assert(sourceJson["icon"] != null);
    assert(sourceJson["url"] != null);
  });

  test("Quick Link Model Test", (){
    var source1 = QuickLinkSource("home", "home", Uri.http("example.org", ""));
    var source2 = QuickLinkSource("analytics", "analytics", Uri.http("example.org", ""));
    var source3 = QuickLinkSource("home", "home", Uri.http("example2.org", ""));

    var model = QuickLinksModel.fromJson({"source":[source1.toJson(), source2.toJson(), source3.toJson()]});
    assert(model.sources.isEmpty);
    model = QuickLinksModel.fromJson({"sources":[source1.toJson(), source2.toJson(), source3.toJson()]});
    assert(model.sources.length == 2);

    var source4 = QuickLinkSource("manage", "manage_accounts", Uri.http("manage.org", ""));

    model.addSource(source4);
    model.removeSource(source1);
    assert(model.sources.first == source2);
    assert(model.sources.last == source4);

    model.swapSource(0, 2);
    assert(model.sources.first == source4);
    assert(model.sources.last == source2);
  });
}