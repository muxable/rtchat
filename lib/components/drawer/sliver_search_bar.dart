import 'package:flutter/material.dart';

class SliverSearchBarWidget extends StatelessWidget {
  final void Function(String) onFilterBySearchBarText;

  const SliverSearchBarWidget({Key? key, required this.onFilterBySearchBarText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
          child: Center(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Colors.blueGrey.withOpacity(0.30)),
              child: Row(
                children: [
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) async {
                        onFilterBySearchBarText(value);
                        // viewersListModel.filteredByText(value);
                      },
                      // onSubmitted: (value) {
                      //   viewersListModel.filteredByText(value);
                      // },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
