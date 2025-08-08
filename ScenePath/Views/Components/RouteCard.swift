//
//  RouteCard.swift
//  ScenePath
//
//  路线卡片组件 - 修复版
//

import SwiftUI

struct RouteCard: View {
    let route: RouteInfo
    let onGoTapped: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onGoTapped) {
            HStack {
                // 左侧图标和类型
                VStack {
                    Image(systemName: route.type.icon)
                        .foregroundColor(route.type.color)
                        .font(.title2)
                    Text(route.type.rawValue)
                        .font(.caption)
                        .foregroundColor(route.type.color)
                        .fontWeight(.medium)
                }
                .frame(width: 70)
                
                // 中间信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Text(route.duration)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Text(route.distance)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !route.price.isEmpty {
                        HStack {
                            Image(systemName: "yensign.circle")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Text(route.price)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(route.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 右侧GO按钮
                HStack {
                    Text("GO")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            .padding(16) // 增加padding
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: isPressed ? 2 : 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: Color.black.opacity(isPressed ? 0.1 : 0.05),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
        }
        .buttonStyle(PlainButtonStyle()) // 移除默认按钮样式
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}
