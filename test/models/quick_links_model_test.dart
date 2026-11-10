import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/quick_links.dart';

QuickLinkSource source(String label) =>
    QuickLinkSource("link", Uri.parse("https://example.com/$label"), label);

List<String> labels(QuickLinksModel model) =>
    model.sources.map((s) => s.label).toList();

void main() {
  group("QuickLinkSource", () {
    test("fromJson falls back to the url when label is missing", () {
      final s = QuickLinkSource.fromJson({
        "icon": "link",
        "url": "https://rtirl.com",
      });
      expect(s.label, "https://rtirl.com");
      expect(s.url, Uri.parse("https://rtirl.com"));
    });

    test("equality uses url and label but not icon", () {
      final url = Uri.parse("https://rtirl.com");
      expect(QuickLinkSource("a", url, "x"), QuickLinkSource("b", url, "x"));
      expect(
        QuickLinkSource("a", url, "x"),
        isNot(QuickLinkSource("a", url, "y")),
      );
      expect(
        QuickLinkSource("a", url, "x"),
        isNot(QuickLinkSource("a", Uri.parse("https://x.com"), "x")),
      );
    });

    test("toString is the url", () {
      expect(source("a").toString(), "https://example.com/a");
    });
  });

  group("QuickLinksModel", () {
    QuickLinksModel model3() =>
        QuickLinksModel.fromJson({})
          ..addSource(source("a"))
          ..addSource(source("b"))
          ..addSource(source("c"));

    test("addSource and removeSource", () {
      final model = model3();
      model.removeSource(source("b"));
      expect(labels(model), ["a", "c"]);
    });

    test("moveSource moving down uses the post-removal index", () {
      // ReorderableListView.onReorderItem reports newIndex after removal, so
      // dragging "a" below "c" yields (0, 2).
      final model = model3();
      model.moveSource(0, 2);
      expect(labels(model), ["b", "c", "a"]);
    });

    test("moveSource moving up", () {
      final model = model3();
      model.moveSource(2, 0);
      expect(labels(model), ["c", "a", "b"]);
    });

    test("moveSource to the same index is a no-op", () {
      final model = model3();
      model.moveSource(1, 1);
      expect(labels(model), ["a", "b", "c"]);
    });

    test("mutations notify listeners", () {
      final model = model3();
      var count = 0;
      model.addListener(() => count++);
      model.addSource(source("d"));
      model.moveSource(0, 1);
      model.removeSource(source("d"));
      expect(count, 3);
    });

    test("json round trip preserves order", () {
      final model = model3()..moveSource(0, 2);
      final decoded = QuickLinksModel.fromJson(model.toJson());
      expect(labels(decoded), ["b", "c", "a"]);
    });
  });
}
