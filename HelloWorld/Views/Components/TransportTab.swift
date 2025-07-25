//
//  TransportTab.swift
//  HelloWorld
//
//  交通方式选择按钮 - 修复版
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
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title2) // 增大图标
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
            .padding(.vertical, 12) // 增加垂直padding
            .padding(.horizontal, 8) // 增加水平padding
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled && isSelected ? type.color.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isEnabled && isSelected ? type.color : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isSelected ? 1.02 : 1.0) // 选中时轻微放大
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
