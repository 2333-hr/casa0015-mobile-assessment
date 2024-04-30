// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'place.dart';
import 'place_tracker_app.dart';
import 'stub_data.dart';

class PlaceDetails extends StatefulWidget {
  final Place place; // 要显示和编辑的地点对象

  const PlaceDetails({
    required this.place, // 必需参数，指定要显示和编辑的地点
    super.key, // 调用父类的构造函数

   });



  @override
  State<PlaceDetails> createState() => _PlaceDetailsState(); // 创建状态对象的工厂方法
}

class _PlaceDetailsState extends State<PlaceDetails> {
  late Place _place; // 地点对象
  GoogleMapController? _mapController; // Google 地图控制器
  final Set<Marker> _markers = {}; // 地图标记集合
  final TextEditingController _nameController =
      TextEditingController(); // 地点名称的文本编辑控制器
  final TextEditingController _descriptionController =
      TextEditingController(); // 地点描述的文本编辑控制器

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_place.name), // 页面标题为地点名称
        backgroundColor: Colors.green[700], // AppBar 背景色
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
            child: IconButton(
              icon: const Icon(Icons.save, size: 30.0), // 保存按钮图标
              onPressed: () {
                _onChanged(_place); // 保存地点信息
                Navigator.pop(context); // 返回上一页
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode()); // 点击空白处隐藏键盘
        },
        child: _detailsBody(), // 显示地点详情主体内容
      ),
    );
  }

  @override
  void initState() {
    _place = widget.place; // 初始化地点信息
    _nameController.text = _place.name; // 将地点名称填充到文本框中
    _descriptionController.text =
        _place.description ?? ''; // 将地点描述填充到文本框中，若为空则填充空字符串
    return super.initState();
  }

  Widget _detailsBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 12.0), // 主体内容的内边距
      children: [
        _NameTextField(
          // 地点名称编辑文本框
          controller: _nameController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(name: value); // 更新地点名称
            });
          },
        ),
        _DescriptionTextField(
          // 地点描述编辑文本框
          controller: _descriptionController,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(description: value); // 更新地点描述
            });
          },
        ),
        _StarBar(
          // 星级评分组件
          rating: _place.starRating,
          onChanged: (value) {
            setState(() {
              _place = _place.copyWith(starRating: value); // 更新地点评分
            });
          },
        ),
        _Map(
          // 地图组件
          center: _place.latLng, // 地图中心点为地点的经纬度
          mapController: _mapController, // 地图控制器
          onMapCreated: _onMapCreated, // 地图创建回调
          markers: _markers, // 地图标记集合
        ),
        const _Reviews(), // 评论组件
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller; // 设置地图控制器
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(_place.latLng.toString()), // 创建标记的唯一标识符
        position: _place.latLng, // 标记的位置
      ));
    });
  }

  void _onChanged(Place value) {
    // 用修改后的地点替换原有的地点
    final newPlaces = List<Place>.from(context.read<AppState>().places);
    final index = newPlaces
        .indexWhere((place) => place.id == value.id); // 找到要替换的地点在列表中的索引
    newPlaces[index] = value; // 替换地点信息

    context.read<AppState>().setPlaces(newPlaces); // 更新应用状态中的地点列表
  }
}

class _DescriptionTextField extends StatelessWidget {
  final TextEditingController controller; // 文本编辑控制器
  final ValueChanged<String> onChanged; // 文本变化回调函数

  const _DescriptionTextField({
    required this.controller, // 必需参数，文本编辑控制器
    required this.onChanged, // 必需参数，文本变化回调函数
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 16.0), // 组件内边距
      child: TextField(
        decoration: const InputDecoration(
          labelText: 'Description', // 描述文本框的标签
          labelStyle: TextStyle(fontSize: 18.0), // 标签文本样式
        ),
        style: const TextStyle(fontSize: 20.0, color: Colors.black87), // 文本样式
        maxLines: null, // 文本框最大行数为null，表示可以无限行
        autocorrect: true, // 自动纠正输入内容
        controller: controller, // 设置文本编辑控制器
        onChanged: (value) {
          onChanged(value); // 调用文本变化回调函数
        },
      ),
    );
  }
}

class _Map extends StatelessWidget {
  final LatLng center; // 地图中心点的经纬度
  final GoogleMapController? mapController; // 地图控制器
  final ArgumentCallback<GoogleMapController> onMapCreated; // 地图创建回调函数
  final Set<Marker> markers; // 地图标记集合

  const _Map({
    required this.center, // 必需参数，地图中心点的经纬度
    required this.mapController, // 必需参数，地图控制器
    required this.onMapCreated, // 必需参数，地图创建回调函数
    required this.markers, // 必需参数，地图标记集合
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0), // 卡片外边距
      elevation: 4, // 卡片阴影
      child: SizedBox(
        width: 340, // 地图容器的宽度
        height: 240, // 地图容器的高度
        child: GoogleMap(
          onMapCreated: onMapCreated, // 设置地图创建回调函数
          initialCameraPosition: CameraPosition(
            target: center, // 初始相机位置为地图中心点
            zoom: 16, // 初始缩放级别
          ),
          markers: markers, // 设置地图标记集合
          zoomGesturesEnabled: false, // 禁用缩放手势
          rotateGesturesEnabled: false, // 禁用旋转手势
          tiltGesturesEnabled: false, // 禁用倾斜手势
          scrollGesturesEnabled: false, // 禁用滚动手势
        ),
      ),
    );
  }
}

class _NameTextField extends StatelessWidget {
  final TextEditingController controller; // 文本编辑控制器
  final ValueChanged<String> onChanged; // 文本变化回调函数

  const _NameTextField({
    required this.controller, // 必需参数，文本编辑控制器
    required this.onChanged, // 必需参数，文本变化回调函数
  });

  
  @override
  Widget build(BuildContext context) {
   return Padding(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 16), // 设置组件内边距
    child: TextField(
      decoration: const InputDecoration(
        labelText: 'Name', // 设置文本框的标签
        labelStyle: TextStyle(fontSize: 18), // 设置标签文本样式
      ),
      style: const TextStyle(fontSize: 20, color: Colors.black87), // 设置文本样式
      autocorrect: true, // 允许自动纠正输入内容
      controller: controller, // 设置文本编辑控制器
      onChanged: (value) {
        onChanged(value); // 调用文本变化回调函数
      },
    ),
  );
  }
}
class _Reviews extends StatelessWidget {
  const _Reviews(); // 评论部件

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 12, 0, 8), // 设置外边距
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Reviews', // 显示评论标题
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline, // 添加下划线装饰
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Column(
          children: StubData.reviewStrings // 显示虚拟数据中的评论字符串
              .map((reviewText) => _buildSingleReview(reviewText)) // 映射每个评论到单个评论部件
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSingleReview(String reviewText) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10), // 设置内边距
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40), // 添加圆形边框
                  border: Border.all(
                    width: 3,
                    color: Colors.grey, // 设置边框颜色
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '5', // 显示评分
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.star, // 显示星形图标
                      color: Colors.amber, // 星形图标颜色
                      size: 36,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16), // 设置宽度间隔
              Expanded(
                child: Text(
                  reviewText, // 显示评论文本
                  style: const TextStyle(fontSize: 20, color: Colors.black87), // 设置文本样式
                  maxLines: null, // 设置文本框最大行数为null，表示可以无限行
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 8, // 设置分割线高度
          color: Colors.grey[700], // 设置分割线颜色
        ),
      ],
    );
  }
}

class _StarBar extends StatelessWidget {
  static const int maxStars = 5; // 星形图标数量

  final int rating; // 评分
  final ValueChanged<int> onChanged; // 评分变化回调函数

  const _StarBar({
    required this.rating, // 必需参数，评分
    required this.onChanged, // 必需参数，评分变化回调函数
  }) : assert(rating >= 0 && rating <= maxStars); // 断言评分在0到5之间

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxStars, (index) {
        return IconButton(
          icon: const Icon(Icons.star), // 显示星形图标
          iconSize: 40, // 设置图标大小
          color: rating > index ? Colors.amber : Colors.grey[400], // 根据评分设置图标颜色
          onPressed: () {
            onChanged(index + 1); // 调用评分变化回调函数
          },
        );
      }).toList(),
    );
  }
}
