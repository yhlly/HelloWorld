//
//  EnhancedLocationSearchBar.swift
//  ScenePath
//
//  增强的地点搜索框组件 - 修复下拉框位置
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
        VStack(alignment: .leading, spacing: 0) {
            // 建议列表（上方显示）
            if showSuggestions && !searchManager.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchManager.suggestions.prefix(5)) { suggestion in
                        Button(action: {
                            selectSuggestion(suggestion)
                        }) {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
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
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(Color(.systemBackground))
                        
                        if suggestion.id != searchManager.suggestions.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.bottom, 4)
                .zIndex(1)
                .transition(.opacity)
            }
            
            // 输入框
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
                                showSuggestions = true
                            } else {
                                searchManager.clearSuggestions()
                                showSuggestions = false
                            }
                        }
                    }
                    .onTapGesture {
                        if !text.isEmpty && !searchManager.suggestions.isEmpty {
                            showSuggestions = true
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        selectedLocation = nil
                        searchManager.clearSuggestions()
                        showSuggestions = false
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
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func selectSuggestion(_ suggestion: LocationSuggestion) {
        text = suggestion.displayText
        selectedLocation = suggestion
        showSuggestions = false
        searchManager.clearSuggestions()
        justSelected = true
    }
}
