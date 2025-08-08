//
//  SpecialRouteSelector.swift
//  HelloWorld
//
//  特殊路线选择组件
//

import SwiftUI

struct SpecialRouteSelector: View {
    @Binding var selectedSpecialRoute: SpecialRouteType
    @State private var showingFullSelector = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 当前选择的特殊路线展示
            Button(action: {
                withAnimation(.spring()) {
                    showingFullSelector.toggle()
                }
            }) {
                HStack {
                    Image(systemName: selectedSpecialRoute.icon)
                        .foregroundColor(selectedSpecialRoute.color)
                        .font(.title3)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedSpecialRoute.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(selectedSpecialRoute.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingFullSelector ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedSpecialRoute.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedSpecialRoute.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 展开的特殊路线选择器
            if showingFullSelector {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(SpecialRouteType.allCases, id: \.self) { routeType in
                        SpecialRouteCard(
                            routeType: routeType,
                            isSelected: selectedSpecialRoute == routeType,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedSpecialRoute = routeType
                                    showingFullSelector = false
                                }
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            }
        }
    }
}

struct SpecialRouteCard: View {
    let routeType: SpecialRouteType
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: routeType.icon)
                    .font(.title2)
                    .foregroundColor(routeType.color)
                    .frame(height: 30)
                
                Text(routeType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // 标签
                HStack {
                    ForEach(routeType.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(routeType.color.opacity(0.2))
                            )
                            .foregroundColor(routeType.color)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? routeType.color.opacity(0.15) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? routeType.color : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isSelected ? routeType.color.opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 4 : 2,
                x: 0,
                y: isSelected ? 2 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// 预览
#Preview {
    VStack {
        SpecialRouteSelector(selectedSpecialRoute: .constant(.scenic))
            .padding()
        
        Spacer()
    }
}
