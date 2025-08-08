//
//  README.md
//  ScenePath
//
//  Created by haliluye on 2025/8/8.
//
/*
项目结构

ScenePath/
├── ContentView.swift                 # 应用主视图，管理不同状态切换
├── ScenePathApp.swift                # 应用入口，集成SwiftData
├── Managers/
│   ├── RouteSimulationPlayer.swift   # 路线模拟播放控制器
│   ├── CollectionManager.swift       # 收集点管理逻辑
│   ├── LocationSearchManager.swift   # 位置搜索服务
│   └── LocationManager.swift         # 定位服务管理
├── Assets.xcassets/
│   ├── AppIcon.appiconset/           # 应用图标资源
│   │   └── Contents.json
│   └── AccentColor.colorset/         # 应用强调色配置
│       └── Contents.json
├── Models/
│   ├── AppState.swift                # 应用状态定义
│   ├── NavigationModels.swift        # 导航相关数据模型
│   ├── CollectibleItem.swift         # 可收集物品数据模型
│   ├── TransportationType.swift      # 交通方式定义
│   ├── RouteType.swift               # 路线类型定义
│   └── SpecialRouteType.swift        # 特殊路线类型定义
├── Extensions/
│   └── CLLocationCoordinate2D+Extensions.swift  # 坐标扩展方法
├── Views/
│   ├── CollectionView.swift          # 收集物品展示视图
│   ├── ARNavigationView.swift        # AR导航视图
│   ├── RoutePreviewView.swift        # 路线预览视图
│   ├── SearchRouteView.swift         # 路线搜索视图
│   ├── Components/
│   │   ├── SpecialRouteSelector.swift     # 特殊路线选择组件
│   │   ├── CollectibleMapOverlay.swift    # 地图收集点叠加层
│   │   ├── TransportTab.swift             # 交通方式选择标签
│   │   ├── EnhancedLocationSearchBar.swift # 增强版位置搜索栏
│   │   └── RouteCard.swift                # 路线信息卡片
│   └── MapViews/
│       ├── EnhancedARNavigationView.swift # 增强版AR导航视图
│       ├── RouteSimulationView.swift      # 路线模拟视图
│       ├── MapViewRepresentable.swift     # 基础地图视图包装
│       ├── ARNavigationMapView.swift      # AR导航地图视图
│       └── EnhancedARSceneView.swift      # 增强版AR场景视图
└── Services/
    └── RouteService.swift            # 路线服务，负责路线规划
*/
