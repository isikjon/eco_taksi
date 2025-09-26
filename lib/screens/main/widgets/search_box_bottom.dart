import 'package:eco_taksi/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;

class SearchBoxBottom extends StatelessWidget {
  const SearchBoxBottom({super.key, required this.sdkContext});

  final sdk.Context sdkContext;

  @override
  Widget build(BuildContext context) {
    final sdk.SearchManager searchManager = sdk.SearchManager.createOnlineManager(sdkContext);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: sdk.DgisSearchWidget(
        colorScheme: const sdk.SearchWidgetColorScheme(
          searchBarBackgroundColor: Colors.transparent,
          searchBarTextFieldColor: Colors.white,
          objectCardTileColor: Colors.white,
          objectCardHighlightedTextStyle: TextStyle(),
          objectCardNormalTextStyle: TextStyle(),
          objectListSeparatorColor: Colors.red,
          objectListBackgroundColor: Colors.white,
        ),
        searchManager: searchManager,
        resultBuilder: (context, objects) {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = objects[index];
              return item.fold(
                // Обработка результатов поиска (DirectoryObject)
                (directoryObject) {
                  return ListTile(
                    title: Text(directoryObject.title),
                    subtitle: Text(directoryObject.subtitle),
                    onTap: () {
                      // Обработка выбора объекта справочника
                      print('Selected: ${directoryObject.title}');
                    },
                  );
                },
                // Обработка поисковых подсказок
                (suggest) {
                  return ListTile(
                    title: Text(suggest.title.text),
                    subtitle: Text(suggest.subtitle.text),
                    onTap: () {
                      if (suggest.handler.isObjectHandler) {
                        final item = suggest.handler.asObjectHandler!.item;
                        print('Selected object: ${item.title}');
                      } else if (suggest.handler.isIncompleteTextHandler) {
                        final queryText = suggest
                            .handler
                            .asIncompleteTextHandler!
                            .queryText;
                        print('Complete search with: $queryText');
                      } else if (suggest.handler.isPerformSearchHandler) {
                        final searchQuery = suggest
                            .handler
                            .asPerformSearchHandler!
                            .searchQuery;
                        print('Perform search query');
                      }
                    },
                  );
                },
              );
            }, childCount: objects.length),
          );
        },
      ),
    );
  }
}
