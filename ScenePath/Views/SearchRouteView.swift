//
//  SearchRouteView.swift
//  ScenePath
//
//  搜索和路线选择界面 - 修复下拉框显示问题
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
    
    @Binding var selectedSpecialRoute: SpecialRouteType
    @State private var showingSpecialRouteInfo = false
    
    let onRouteSelected: (RouteInfo) -> Void
    let onSearchRoutes: () -> Void
    
    var body: some View {
        // 使用ZStack作为根容器，确保正确的z轴顺序
        ZStack {
            // 主背景和滚动内容区域
            VStack(spacing: 0) {
                // 标题区域
                Text("路线规划")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.top, 8)
                
                // 包含地点输入区域的ZStack，确保下拉框显示在最上层
                ZStack(alignment: .top) {
                    // 地点输入区域
                    VStack(spacing: 12) {
                        // 起点和使用我的位置按钮
                        HStack(alignment: .center, spacing: 8) {
                            // 起点输入框
                            EnhancedLocationSearchBar(
                                placeholder: "起点",
                                text: $startLocation,
                                selectedLocation: $selectedStartLocation,
                                icon: "location.circle"
                            )
                            .onChange(of: selectedStartLocation) { _ in
                                checkAutoSearch()
                            }
                            
                            // 使用我的位置按钮（更紧凑）
                            Button(action: {
                                print("使用我的位置 button pressed")
                                myLocationActive = true
                                locationManager.requestLocation()
                            }) {
                                HStack(spacing: 4) {
                                    if locationManager.isReverseGeocoding {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "location.fill")
                                    }
                                    Text(locationManager.isReverseGeocoding ? "定位..." : "我的位置")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                            }
                            .disabled(locationManager.isReverseGeocoding)
                            .opacity(locationManager.isReverseGeocoding ? 0.6 : 1.0)
                        }
                        
                        // 显示位置错误信息（如果有）
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
                        
                        // 终点和交换按钮
                        HStack(alignment: .center, spacing: 8) {
                            EnhancedLocationSearchBar(
                                placeholder: "终点",
                                text: $endLocation,
                                selectedLocation: $selectedEndLocation,
                                icon: "location.fill"
                            )
                            .onChange(of: selectedEndLocation) { _ in
                                checkAutoSearch()
                            }
                            
                            // 交换按钮（更紧凑）
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
                                    .padding(8)
                                    .background(Circle().fill(Color(.systemGray6)))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .zIndex(1) // 主要内容区域的z-index
                }
                .zIndex(10) // 确保搜索区域比其他内容的z-index高
                
                // 特殊路线选择器（更紧凑）
                VStack(spacing: 8) {
                    HStack {
                        Text("路线偏好")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSpecialRouteInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    
                    SpecialRouteSelector(selectedSpecialRoute: $selectedSpecialRoute)
                        .padding(.horizontal)
                        .onChange(of: selectedSpecialRoute) { _, newValue in
                            if hasSearched && canSearch {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onSearchRoutes()
                                }
                            }
                        }
                }
                .padding(.top, 8)
                .zIndex(5) // 特殊路线选择器的z-index
                
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
                        .padding(.vertical, 12)
                        .background(isSearching ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isSearching)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // 已选择的位置信息（更紧凑）
                if selectedStartLocation != nil || selectedEndLocation != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        if let start = selectedStartLocation {
                            HStack {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                                Text("起点: \(start.displayText)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        if let end = selectedEndLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                    .font(.caption2)
                                Text("终点: \(end.displayText)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        
                        if selectedSpecialRoute != .none {
                            HStack {
                                Image(systemName: selectedSpecialRoute.icon)
                                    .foregroundColor(selectedSpecialRoute.color)
                                    .font(.caption2)
                                Text("偏好: \(selectedSpecialRoute.rawValue)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                // 错误信息
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .font(.caption)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // 路线选择区域（通过减少上方空间来扩大）
                if hasSearched && !routes.isEmpty {
                    VStack(spacing: 0) {
                        // 交通方式选项卡
                        HStack(spacing: 0) {
                            ForEach(TransportationType.allCases, id: \.self) { type in
                                TransportTab(
                                    type: type,
                                    isSelected: selectedTransportType == type,
                                    routeCount: routes[type]?.count ?? 0,
                                    isEnabled: true,
                                    action: {
                                        selectedTransportType = type
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // 路线列表（扩展）
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if let routeList = routes[selectedTransportType], !routeList.isEmpty {
                                    ForEach(routeList, id: \.id) { route in
                                        Button(action: {
                                            onRouteSelected(route)
                                        }) {
                                            RouteCard(route: route, onGoTapped: {
                                                onRouteSelected(route)
                                            })
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
            .zIndex(1) // 主内容的z-index
        }
        .onChange(of: locationManager.currentLocationName) { _, newValue in
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
