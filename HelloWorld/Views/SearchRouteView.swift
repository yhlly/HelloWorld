//
//  SearchRouteView.swift
//  HelloWorld
//
//  搜索和路线选择界面 - 添加特殊路线功能
//

import SwiftUI
import MapKit

struct SearchRouteView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var myLocationActive = false
    @Binding var startLocation: String
    @Binding var endLocation: String
    @Binding var selectedStartLocation: LocationSuggestion?
    @Binding var selectedEndLocation: LocationSuggestion?
    @Binding var selectedTransportType: TransportationType
    @Binding var routes: [TransportationType: [RouteInfo]]
    @Binding var isSearching: Bool
    @Binding var hasSearched: Bool
    @Binding var errorMessage: String
    
    // 新增特殊路线状态
    @State private var selectedSpecialRoute: SpecialRouteType = .none
    @State private var showingSpecialRouteInfo = false
    
    let onRouteSelected: (RouteInfo) -> Void
    let onSearchRoutes: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部搜索区域
            VStack(spacing: 20) {
                Text("路线规划")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 地点输入区域
                VStack(spacing: 15) {
                    EnhancedLocationSearchBar(
                        placeholder: "起点",
                        text: $startLocation,
                        selectedLocation: $selectedStartLocation,
                        icon: "location.circle"
                    )
                    .onChange(of: selectedStartLocation) { _ in
                        checkAutoSearch()
                    }
                    
                    // 使用我的位置按钮
                    HStack {
                        Button(action: {
                            print("使用我的位置 button pressed")
                            myLocationActive = true
                            locationManager.requestLocation()
                        }) {
                            HStack(spacing: 8) {
                                if locationManager.isReverseGeocoding {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                }
                                Text(locationManager.isReverseGeocoding ? "定位中..." : "使用我的位置")
                                    .font(.callout)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(locationManager.isReverseGeocoding)
                        .opacity(locationManager.isReverseGeocoding ? 0.6 : 1.0)
                        
                        Spacer()
                    }
                    .padding(.leading)
                    
                    // 显示位置错误信息
                    if let locationError = locationManager.locationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(locationError)
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // 交换按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            let tempLocation = startLocation
                            let tempSelected = selectedStartLocation
                            
                            startLocation = endLocation
                            selectedStartLocation = selectedEndLocation
                            
                            endLocation = tempLocation
                            selectedEndLocation = tempSelected
                            
                            checkAutoSearch()
                        }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .padding(12)
                                .background(Circle().fill(Color(.systemGray6)))
                        }
                        Spacer()
                    }
                    
                    EnhancedLocationSearchBar(
                        placeholder: "终点",
                        text: $endLocation,
                        selectedLocation: $selectedEndLocation,
                        icon: "location.fill"
                    )
                    .onChange(of: selectedEndLocation) { _ in
                        checkAutoSearch()
                    }
                }
                .padding(.horizontal)
                
                // 新增：特殊路线选择器
                VStack(spacing: 12) {
                    HStack {
                        Text("路线偏好")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSpecialRouteInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    SpecialRouteSelector(selectedSpecialRoute: $selectedSpecialRoute)
                        .padding(.horizontal)
                        .onChange(of: selectedSpecialRoute) { _ in
                            // 当特殊路线类型改变时，如果已经搜索过，重新搜索
                            if hasSearched && canSearch {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSearchRoutes()
                                }
                            }
                        }
                }
                
                // 搜索按钮
                if canSearch && !hasSearched {
                    Button(action: {
                        onSearchRoutes()
                    }) {
                        HStack {
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isSearching ? "搜索中..." : "搜索路线")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSearching ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isSearching)
                    .padding(.horizontal)
                }
                
                // 选择的位置显示
                if selectedStartLocation != nil || selectedEndLocation != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let start = selectedStartLocation {
                            HStack {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.green)
                                Text("起点: \(start.displayText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        if let end = selectedEndLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                Text("终点: \(end.displayText)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        // 显示选择的特殊路线
                        if selectedSpecialRoute != .none {
                            HStack {
                                Image(systemName: selectedSpecialRoute.icon)
                                    .foregroundColor(selectedSpecialRoute.color)
                                Text("偏好: \(selectedSpecialRoute.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 错误信息
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .font(.caption)
                }
            }
            .background(Color(.systemBackground))
            
            // 路线选择区域
            if hasSearched && !routes.isEmpty {
                VStack(spacing: 0) {
                    // 分隔线
                    Divider()
                        .padding(.vertical, 10)
                    
                    // 交通方式选择标签
                    HStack(spacing: 0) {
                        ForEach(TransportationType.allCases, id: \.self) { type in
                            Button(action: {
                                selectedTransportType = type
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                        .foregroundColor(selectedTransportType == type ? type.color : .gray)
                                    
                                    Text(type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(selectedTransportType == type ? type.color : .gray)
                                    
                                    if let routeCount = routes[type]?.count, routeCount > 0 {
                                        Text("\(routeCount)条路线")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("查找中...")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedTransportType == type ? type.color.opacity(0.1) : Color.clear
                                )
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // 路线列表
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if let routeList = routes[selectedTransportType], !routeList.isEmpty {
                                ForEach(routeList, id: \.id) { route in
                                    Button(action: {
                                        onRouteSelected(route)
                                    }) {
                                        EnhancedRouteCardContent(route: route)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                VStack {
                                    Image(systemName: selectedTransportType.icon)
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("正在为您查找\(selectedTransportType.rawValue)路线...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                }
            } else if hasSearched && routes.isEmpty && !isSearching {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("未找到可用路线")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else if !hasSearched {
                Spacer()
            }
        }
        .onChange(of: locationManager.currentLocationName) { oldValue, newValue in
            guard myLocationActive,
                  let coord = locationManager.currentLocation,
                  let locationName = newValue else { return }
            
            let myLoc = LocationSuggestion(
                title: locationName,
                subtitle: "",
                coordinate: coord,
                completion: nil
            )
            startLocation = myLoc.displayText
            selectedStartLocation = myLoc
            myLocationActive = false
            checkAutoSearch()
        }
        .sheet(isPresented: $showingSpecialRouteInfo) {
            SpecialRouteInfoView()
        }
    }
    
    // 检查是否可以搜索
    private var canSearch: Bool {
        return selectedStartLocation != nil && selectedEndLocation != nil
    }
    
    // 自动搜索检查
    private func checkAutoSearch() {
        if canSearch && !hasSearched && !isSearching {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.canSearch && !self.hasSearched && !self.isSearching {
                    self.onSearchRoutes()
                }
            }
        }
    }
}

// 增强的路线卡片内容组件，支持特殊路线信息
struct EnhancedRouteCardContent: View {
    let route: RouteInfo
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: route.type.icon)
                    .foregroundColor(route.type.color)
                    .font(.title2)
                Text(route.type.rawValue)
                    .font(.caption)
                    .foregroundColor(route.type.color)
            }
            .frame(width: 70)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(route.duration)
                        .font(.headline)
                    
                    Spacer()
                    
                    // 特殊路线标识
                    if route.specialRouteType != .none {
                        HStack(spacing: 4) {
                            Image(systemName: route.specialRouteType.icon)
                                .foregroundColor(route.specialRouteType.color)
                                .font(.caption)
                            Text(route.specialRouteType.rawValue)
                                .font(.caption2)
                                .foregroundColor(route.specialRouteType.color)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(route.specialRouteType.color.opacity(0.15))
                        )
                    }
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                    Text(route.distance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 难度指示
                    HStack(spacing: 2) {
                        Image(systemName: route.difficulty.icon)
                            .foregroundColor(route.difficulty.color)
                            .font(.caption2)
                        Text(route.difficulty.rawValue)
                            .font(.caption2)
                            .foregroundColor(route.difficulty.color)
                    }
                }
                
                if !route.price.isEmpty {
                    HStack {
                        Image(systemName: "yensign.circle")
                            .foregroundColor(.secondary)
                        Text(route.price)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(route.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 路线亮点
                if !route.highlights.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(route.highlights.prefix(3), id: \.self) { highlight in
                                Text(highlight)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // GO按钮样式
            Text("GO")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 50, height: 35)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// 特殊路线信息视图
struct SpecialRouteInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("路线偏好说明")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(SpecialRouteType.allCases, id: \.self) { routeType in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: routeType.icon)
                                    .foregroundColor(routeType.color)
                                    .font(.title3)
                                
                                Text(routeType.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(routeType.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                ForEach(routeType.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(routeType.color.opacity(0.15))
                                        )
                                        .foregroundColor(routeType.color)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("路线偏好")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
