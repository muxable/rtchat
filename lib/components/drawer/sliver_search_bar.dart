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
          padding: const EdgeInsets.fromLTRB(32, 64, 32, 8),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  color: Colors.blueGrey.withOpacity(0.30)),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search viewers',
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
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
