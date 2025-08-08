//
//  EnhancedLocationSearchBar.swift
//  ScenePath
//
//  增强的地点搜索框组件 - 修复浮动下拉框版本
//

import SwiftUI

struct EnhancedLocationSearchBar: View {
    let placeholder: String
    @Binding var text: String
    @Binding var selectedLocation: LocationSuggestion?
    let icon: String
    @StateObject private var searchManager = LocationSearchManager()
    @State private var showSuggestions = false
    @State private var searchTimer: Timer?
    @State private var justSelected = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // 主要搜索框
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: text) { newValue in
                        if justSelected {
                            justSelected = false
                            return
                        }
                        selectedLocation = nil
                        
                        searchTimer?.invalidate()
                        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                            if !newValue.isEmpty {
                                searchManager.search(query: newValue)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showSuggestions = true
                                }
                            } else {
                                searchManager.clearSuggestions()
                                withAnimation {
                                    showSuggestions = false
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        if !text.isEmpty && !searchManager.suggestions.isEmpty {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSuggestions = true
                            }
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        selectedLocation = nil
                        searchManager.clearSuggestions()
                        withAnimation {
                            showSuggestions = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                if searchManager.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: showSuggestions ? .black.opacity(0.15) : .black.opacity(0.05),
                            radius: showSuggestions ? 8 : 4,
                            x: 0,
                            y: showSuggestions ? 4 : 2)
            )
            
            // 下拉建议列表 - 修复: 使用 ZStack 将其放在顶层，并设置正确的 zIndex
            if showSuggestions && !searchManager.suggestions.isEmpty {
                SuggestionsDropdown(
                    suggestions: searchManager.suggestions,
                    onSelect: { suggestion in
                        selectSuggestion(suggestion)
                    }
                )
                .offset(y: 60) // 定位到搜索框下方
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
                .zIndex(100) // 确保下拉框在最上层
            }
        }
        .frame(height: 50) // 固定高度，确保不会被下拉框影响
    }
    
    private func selectSuggestion(_ suggestion: LocationSuggestion) {
        withAnimation {
            text = suggestion.displayText
            selectedLocation = suggestion
            showSuggestions = false
        }
        searchManager.clearSuggestions()
        justSelected = true
    }
}

// 提取出的下拉建议组件
struct SuggestionsDropdown: View {
    let suggestions: [LocationSuggestion]
    let onSelect: (LocationSuggestion) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.prefix(5)) { suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(suggestion.title)
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .contentShape(Rectangle())
                    )
                    .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
                
                if suggestion.id != suggestions.prefix(5).last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// 用于SearchRouteView的整体搜索栏
struct LocationSearchSection: View {
    @Binding var startLocation: String
    @Binding var endLocation: String
    @Binding var selectedStartLocation: LocationSuggestion?
    @Binding var selectedEndLocation: LocationSuggestion?
    @StateObject var locationManager = LocationManager()
    @State private var myLocationActive = false
    
    var onLocationSelected: (() -> Void)?
    
    var body: some View {
        ZStack {
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
                        onLocationSelected?()
                    }
                    
                    // 使用我的位置按钮
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
                        onLocationSelected?()
                    }
                    
                    // 交换按钮
                    Button(action: {
                        let tempLocation = startLocation
                        let tempSelected = selectedStartLocation
                        
                        startLocation = endLocation
                        selectedStartLocation = selectedEndLocation
                        
                        endLocation = tempLocation
                        selectedEndLocation = tempSelected
                        
                        onLocationSelected?()
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Circle().fill(Color(.systemGray6)))
                    }
                }
            }
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
            
            onLocationSelected?()
        }
    }
}
