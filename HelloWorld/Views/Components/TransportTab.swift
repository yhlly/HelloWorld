//
//  TransportTab.swift
//  HelloWorld
//
//  交通方式选择按钮 - 优化版
//

import SwiftUI

struct TransportTab: View {
    let type: TransportationType
    let isSelected: Bool
    let routeCount: Int
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3) // 稍微小一点的图标
                    .foregroundColor(isEnabled ? (isSelected ? type.color : .gray) : .gray.opacity(0.5))
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isEnabled ? (isSelected ? type.color : .gray) : .gray.opacity(0.5))
                
                if routeCount > 0 {
                    Text("\(routeCount)条路线")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if !isEnabled {
                    Text("暂不支持")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else {
                    Text("查找中...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8) // 减小垂直内边距
            .padding(.horizontal, 6) // 减小水平内边距
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isEnabled && isSelected ? type.color.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isEnabled && isSelected ? type.color : Color.clear,
                                lineWidth: isSelected ? 1.5 : 0 // 更细的边框
                            )
                    )
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isSelected ? 1.01 : 1.0) // 减小缩放效果
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
