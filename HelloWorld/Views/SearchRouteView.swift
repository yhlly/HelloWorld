//
//  SearchRouteView.swift
//  HelloWorld
//
//  搜索和路线选择界面 - 修复版
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
                    
                    // 使用我的位置按钮 - 改善样式和逻辑
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
                    
                    // 交换按钮 - 增大点击区域
                    HStack {
                        Spacer()
                        Button(action: {
                            // 交换起点和终点
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
                                .padding(12) // 增大点击区域
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
                
                // 搜索按钮 - 改善样式
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
                        .padding(.vertical, 16) // 增加垂直padding
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
                    
                    // 交通方式选择标签 - 改善点击区域
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
                                .padding(.vertical, 12) // 增加点击区域
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
                                        RouteCardContent(route: route)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // 移除默认按钮样式
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
            // 当地址名称更新时，更新UI
            guard myLocationActive,
                  let coord = locationManager.currentLocation,
                  let locationName = newValue else { return }
            
            // 构造带有实际地址的LocationSuggestion
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
    }
    
    // 检查是否可以搜索
    private var canSearch: Bool {
        return selectedStartLocation != nil && selectedEndLocation != nil
    }
    
    // 自动搜索检查
    private func checkAutoSearch() {
        // 如果两个位置都已选择且还没有搜索过，自动触发搜索
        if canSearch && !hasSearched && !isSearching {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.canSearch && !self.hasSearched && !self.isSearching {
                    self.onSearchRoutes()
                }
            }
        }
    }
}

// 独立的路线卡片内容组件，提高重用性
struct RouteCardContent: View {
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
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                    Text(route.distance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
