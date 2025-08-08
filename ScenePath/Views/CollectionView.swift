//
//  CollectionView.swift
//  HelloWorld
//
//  收集物品展示页面
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.dismiss) private var dismiss
    let collectionManager: CollectionManager
    
    @State private var selectedCategory: CollectibleCategory? = nil
    @State private var showingItemDetail = false
    @State private var selectedItem: CollectibleItem? = nil
    
    private var stats: (total: Int, byCategory: [CollectibleCategory: Int]) {
        collectionManager.getCollectionStats()
    }
    
    private var filteredItems: [CollectibleItem] {
        if let category = selectedCategory {
            return collectionManager.collectedItems.filter { $0.category == category }
        }
        return collectionManager.collectedItems
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部统计区域
                VStack(spacing: 16) {
                    // 总体统计
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("我的收藏")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("已收集 \(stats.total) 个物品")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 收集进度环
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 8)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: min(Double(stats.total) / 50.0, 1.0))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(stats.total)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 分类统计
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 全部按钮
                            CategoryStatsCard(
                                category: nil,
                                count: stats.total,
                                isSelected: selectedCategory == nil,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedCategory = nil
                                    }
                                }
                            )
                            
                            // 各分类按钮
                            ForEach(CollectibleCategory.allCases, id: \.self) { category in
                                CategoryStatsCard(
                                    category: category,
                                    count: stats.byCategory[category] ?? 0,
                                    isSelected: selectedCategory == category,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedCategory = selectedCategory == category ? nil : category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // 收集物品列表
                if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: selectedCategory?.iconName ?? "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text(selectedCategory == nil ? "还没有收集任何物品" : "还没有收集\(selectedCategory!.rawValue)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("在特殊路线导航中靠近收集点即可收集")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredItems, id: \.id) { item in
                                CollectionItemCard(item: item) {
                                    selectedItem = item
                                    showingItemDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingItemDetail) {
            if let item = selectedItem {
                CollectionItemDetailView(item: item)
            }
        }
    }
}

// 分类统计卡片
struct CategoryStatsCard: View {
    let category: CollectibleCategory?
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let category = category {
                    Image(systemName: category.iconName)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : colorForCategory(category))
                } else {
                    Image(systemName: "square.grid.2x2")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                }
                
                Text(category?.rawValue ?? "全部")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? (category != nil ? colorForCategory(category!) : .blue) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .clear : Color(.systemGray4), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? .black.opacity(0.2) : .clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func colorForCategory(_ category: CollectibleCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

// 收集物品卡片
struct CollectionItemCard: View {
    let item: CollectibleItem
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 图标
                ZStack {
                    Circle()
                        .fill(colorForCategory(item.category).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: item.iconName)
                        .font(.title2)
                        .foregroundColor(colorForCategory(item.category))
                }
                
                // 信息
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(item.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(colorForCategory(item.category).opacity(0.2))
                        )
                        .foregroundColor(colorForCategory(item.category))
                    
                    Text(formatDate(item.collectedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: .black.opacity(0.05),
                radius: 2,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private func colorForCategory(_ category: CollectibleCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// 收集物品详情视图
struct CollectionItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: CollectibleItem
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部图标和基本信息
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(colorForCategory(item.category).opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: item.iconName)
                                .font(.system(size: 50))
                                .foregroundColor(colorForCategory(item.category))
                        }
                        
                        VStack(spacing: 8) {
                            Text(item.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(item.category.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(colorForCategory(item.category).opacity(0.2))
                                )
                                .foregroundColor(colorForCategory(item.category))
                        }
                    }
                    
                    // 详细信息
                    VStack(spacing: 20) {
                        InfoRow(title: "描述", value: item.itemDescription, icon: "text.bubble")
                        InfoRow(title: "收集时间", value: formatFullDate(item.collectedAt), icon: "clock")
                        InfoRow(title: "路线类型", value: item.routeType, icon: "map")
                        InfoRow(title: "位置", value: "\(String(format: "%.4f", item.latitude)), \(String(format: "%.4f", item.longitude))", icon: "location")
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("收集详情")
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
    
    private func colorForCategory(_ category: CollectibleCategory) -> Color {
        switch category.color {
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 信息行组件
struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 26)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}


