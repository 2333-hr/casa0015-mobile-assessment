// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'place.dart';
import 'place_tracker_app.dart';

class PlaceList extends StatefulWidget {
  const PlaceList({super.key});

  @override
  State<PlaceList> createState() => _PlaceListState();
}

class _PlaceListState extends State<PlaceList> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AppState>(context);
    return Column(
      children: [
        _ListCategoryButtonBar(
          selectedCategory: state.selectedCategory,
          onCategoryChanged: (value) => _onCategoryChanged(value),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
            controller: _scrollController,
            shrinkWrap: true,
            children: state.places
                .where((place) => place.category == state.selectedCategory)
                .map((place) => _PlaceListTile(place: place))
                .toList(),
          ),
        ),
      ],
    );
  }

  void _onCategoryChanged(PlaceCategory newCategory) {
    _scrollController.jumpTo(0.0);
    Provider.of<AppState>(context, listen: false)
        .setSelectedCategory(newCategory);
  }
}

class _CategoryButton extends StatelessWidget {
  final PlaceCategory category;

  final bool selected;
  final ValueChanged<PlaceCategory> onCategoryChanged;

  const _CategoryButton({
    required this.category,
    required this.selected,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final buttonText = switch (category) {
      PlaceCategory.favorite => 'Favorites',
      PlaceCategory.visited => 'Visited',
      PlaceCategory.wantToGo => 'Want To Go',
      PlaceCategory.asdo => "123",
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? Colors.blue : Colors.transparent,
          ),
        ),
      ),
      child: ButtonTheme(
        height: 50.0,
        child: TextButton(
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: selected ? 20.0 : 18.0, // 选中时字体放大
              color: selected ? Colors.blue : Colors.black87, // 选中时文本颜色为蓝色，未选中时为黑色
            ),
          ),
          onPressed: () => onCategoryChanged(category), // 点击按钮时调用回调函数，传递当前地点分类
        ),
      ),
    );
  }
}


// 地点分类按钮栏
class _ListCategoryButtonBar extends StatelessWidget {
  final PlaceCategory selectedCategory;                  // 当前选定的地点分类
  final ValueChanged<PlaceCategory> onCategoryChanged;   // 当分类变化时的回调函数

  const _ListCategoryButtonBar({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CategoryButton(
          category: PlaceCategory.favorite,
          selected: selectedCategory == PlaceCategory.favorite,
          onCategoryChanged: onCategoryChanged,
        ),
        _CategoryButton(
          category: PlaceCategory.visited,
          selected: selectedCategory == PlaceCategory.visited,
          onCategoryChanged: onCategoryChanged,
        ),
        _CategoryButton(
          category: PlaceCategory.wantToGo,
          selected: selectedCategory == PlaceCategory.wantToGo,
          onCategoryChanged: onCategoryChanged,
        ),
      ],
    );
  }
}

// 地点列表项
class _PlaceListTile extends StatelessWidget {
  final Place place;   // 地点对象

  const _PlaceListTile({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/place/${place.id}'),   // 点击地点时导航至相应的页面
      child: Container(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,   // 地点名称
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
              maxLines: 3,
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  size: 28.0,
                  color: place.starRating > index   // 根据星级显示星星的颜色
                      ? Colors.amber
                      : Colors.grey[400],
                );
              }).toList(),
            ),
            Text(
              place.description ?? '',   // 地点描述（如果有）
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16.0),
            Divider(
              height: 2.0,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }
}
