//
//  EnhancedARSceneView.swift
//  ScenePath
//
//  简化的AR场景视图，专注于收集功能
//

import SwiftUI
import ARKit
import SceneKit
import MapKit

// 增强的AR场景视图，支持收集功能
struct EnhancedARSceneView: UIViewRepresentable {
    @Binding var currentInstruction: NavigationInstruction?
    @Binding var isNavigating: Bool
    @Binding var userLocation: CLLocationCoordinate2D?
    
    let collectionManager: CollectionManager
    let route: RouteInfo
    let onCollectionTapped: (CollectiblePoint) -> Void
    
    func makeUIView(context: Context) -> ARSCNView {
        print("🎯 DEBUG: 创建ARSCNView")
        
        let arView = ARSCNView()
        
        // 配置AR会话
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        // 检查AR支持
        if ARWorldTrackingConfiguration.isSupported {
            arView.session.run(configuration)
            print("  ✅ AR会话启动成功")
        } else {
            print("  ❌ AR不支持")
        }
        
        arView.delegate = context.coordinator
        
        // 设置场景
        arView.scene = SCNScene()
        arView.antialiasingMode = .multisampling4X
        arView.preferredFramesPerSecond = 60
        
        // 启用默认光照
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        
        // 添加手势识别器
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        print("  ✅ ARSCNView配置完成")
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        print("🎯 DEBUG: updateUIView 开始")
        
        context.coordinator.updateARContent(
            arView: uiView,
            instruction: currentInstruction,
            isNavigating: isNavigating,
            userLocation: userLocation,
            collectionManager: collectionManager,
            route: route,
            onCollectionTapped: onCollectionTapped
        )
        
        print("  ✅ updateUIView 完成")
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        private var arrowNode: SCNNode?
        private var textNode: SCNNode?
        private var distanceNode: SCNNode?
        private var collectibleNodes: [String: (node: SCNNode, collectible: CollectiblePoint)] = [:]
        
        func updateARContent(
            arView: ARSCNView,
            instruction: NavigationInstruction?,
            isNavigating: Bool,
            userLocation: CLLocationCoordinate2D?,
            collectionManager: CollectionManager,
            route: RouteInfo,
            onCollectionTapped: @escaping (CollectiblePoint) -> Void
        ) {
            print("🎯 DEBUG: updateARContent 开始")
            
            // 清除之前的导航内容
            clearNavigationNodes()
            
            // 添加导航内容
            if let instruction = instruction {
                print("  🧭 添加导航指令: \(instruction.instruction)")
                createDirectionArrow(arView: arView, instruction: instruction)
                createFloatingText(arView: arView, instruction: instruction)
                createDistanceIndicator(arView: arView, instruction: instruction)
            }
            
            // 更新收集点
            updateCollectibleNodes(
                arView: arView,
                userLocation: userLocation,
                collectionManager: collectionManager,
                onCollectionTapped: onCollectionTapped
            )
            
            print("  ✅ updateARContent 完成")
        }
        
        private func clearNavigationNodes() {
            arrowNode?.removeFromParentNode()
            textNode?.removeFromParentNode()
            distanceNode?.removeFromParentNode()
            arrowNode = nil
            textNode = nil
            distanceNode = nil
        }
        
        // 更新收集点显示
        private func updateCollectibleNodes(
            arView: ARSCNView,
            userLocation: CLLocationCoordinate2D?,
            collectionManager: CollectionManager,
            onCollectionTapped: @escaping (CollectiblePoint) -> Void
        ) {
            print("🎯 DEBUG: updateCollectibleNodes 开始")
            
            guard let userLocation = userLocation else {
                print("  ⚠️ 用户位置为空")
                return
            }
            
            // 获取范围内的收集点
            let collectiblesInRange = collectionManager.collectiblesInRange(of: userLocation)
            print("  🎯 范围内收集点: \(collectiblesInRange.count)个")
            
            // 移除不在范围内的收集点节点
            let currentCollectibleIds = Set(collectiblesInRange.map { $0.id.uuidString })
            let nodesToRemove = collectibleNodes.keys.filter { !currentCollectibleIds.contains($0) }
            
            for nodeId in nodesToRemove {
                print("  🗑️ 移除收集点节点: \(collectibleNodes[nodeId]?.collectible.name ?? nodeId)")
                collectibleNodes[nodeId]?.node.removeFromParentNode()
                collectibleNodes.removeValue(forKey: nodeId)
            }
            
            // 添加或更新范围内的收集点
            for collectible in collectiblesInRange {
                let nodeId = collectible.id.uuidString
                
                if collectibleNodes[nodeId] == nil && !collectible.isCollected {
                    // 创建新的收集点节点
                    print("  ➕ 创建收集点节点: \(collectible.name)")
                    
                    let collectibleNode = createCollectibleNode(for: collectible, userLocation: userLocation)
                    collectibleNode.name = nodeId // 设置节点名称以便识别
                    arView.scene.rootNode.addChildNode(collectibleNode)
                    collectibleNodes[nodeId] = (node: collectibleNode, collectible: collectible)
                    
                    print("    ✅ 收集点节点创建成功: \(collectible.name)")
                } else if collectible.isCollected && collectibleNodes[nodeId] != nil {
                    // 移除已收集的收集点
                    print("  🗑️ 移除已收集的收集点: \(collectible.name)")
                    collectibleNodes[nodeId]?.node.removeFromParentNode()
                    collectibleNodes.removeValue(forKey: nodeId)
                }
            }
            
            print("  📊 当前显示的收集点节点: \(collectibleNodes.count)个")
        }
        
        // 创建收集点3D节点
        private func createCollectibleNode(for collectible: CollectiblePoint, userLocation: CLLocationCoordinate2D) -> SCNNode {
            print("🎯 DEBUG: createCollectibleNode for \(collectible.name)")
            
            let node = SCNNode()
            
            // 计算相对位置
            let distance = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                .distance(from: CLLocation(latitude: collectible.coordinate.latitude, longitude: collectible.coordinate.longitude))
            
            print("  📏 实际距离: \(Int(distance))米")
            
            // 计算方向角度
            let deltaLat = collectible.coordinate.latitude - userLocation.latitude
            let deltaLng = collectible.coordinate.longitude - userLocation.longitude
            let angle = atan2(deltaLng, deltaLat)
            
            // 限制显示距离，避免过远的点，但保持比例
            let displayDistance = min(distance / 20, 3.0) // 20米实际距离 = 1米显示距离，最远3米
            
            let x = Float(displayDistance * sin(Double(angle)))
            let z = -Float(displayDistance * cos(Double(angle))) // Z轴向前为负
            let y = Float(1.5) // 固定高度
            
            node.position = SCNVector3(x, y, z)
            
            print("  📍 AR位置: x=\(x), y=\(y), z=\(z)")
            print("  🧭 方向角度: \(String(format: "%.1f", angle * 180 / .pi))度")
            
            // 创建收集点几何体 - 使用更明显的形状
            let sphere = SCNSphere(radius: 0.15) // 增大半径
            let material = SCNMaterial()
            
            // 根据类别设置颜色
            let color = getUIColorForCategory(collectible.category)
            material.diffuse.contents = color
            material.emission.contents = color.withAlphaComponent(0.5) // 增强发光效果
            material.metalness.contents = 0.8
            material.roughness.contents = 0.2
            sphere.materials = [material]
            
            let sphereNode = SCNNode(geometry: sphere)
            node.addChildNode(sphereNode)
            
            // 添加类别图标文字
            let iconText = SCNText(string: getEmojiForCategory(collectible.category), extrusionDepth: 0.02)
            iconText.font = UIFont.systemFont(ofSize: 0.2) // 增大字体
            iconText.firstMaterial?.diffuse.contents = UIColor.white
            iconText.firstMaterial?.emission.contents = UIColor.white
            
            let iconNode = SCNNode(geometry: iconText)
            iconNode.position = SCNVector3(-0.1, 0.2, 0.05) // 调整位置
            node.addChildNode(iconNode)
            
            // 添加名称文字（小一些）
            let nameText = SCNText(string: collectible.name, extrusionDepth: 0.01)
            nameText.font = UIFont.systemFont(ofSize: 0.08)
            nameText.firstMaterial?.diffuse.contents = UIColor.white
            nameText.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.8)
            
            let nameNode = SCNNode(geometry: nameText)
            nameNode.position = SCNVector3(-0.3, -0.3, 0.05)
            
            // 名称始终面向用户
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            nameNode.constraints = [billboardConstraint]
            
            node.addChildNode(nameNode)
            
            // 添加强烈的脉动动画
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.4, duration: 0.8),
                SCNAction.scale(to: 1.0, duration: 0.8)
            ])
            let repeatPulse = SCNAction.repeatForever(pulseAction)
            sphereNode.runAction(repeatPulse)
            
            // 添加浮动动画
            let floatAction = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 1.5),
                SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 1.5)
            ])
            let repeatFloat = SCNAction.repeatForever(floatAction)
            node.runAction(repeatFloat)
            
            print("  ✅ 收集点节点创建完成")
            return node
        }
        
        // 获取类别对应的Emoji
        private func getEmojiForCategory(_ category: CollectibleCategory) -> String {
            switch category {
            case .food:
                return "🍜"
            case .scenic:
                return "🏔️"
            case .attraction:
                return "📸"
            case .landmark:
                return "🏛️"
            case .culture:
                return "🎭"
            }
        }
        
        // 获取类别对应的UIColor
        private func getUIColorForCategory(_ category: CollectibleCategory) -> UIColor {
            switch category.color {
            case "orange": return .systemOrange
            case "green": return .systemGreen
            case "blue": return .systemBlue
            case "purple": return .systemPurple
            case "red": return .systemRed
            default: return .systemGray
            }
        }
        
        // 处理点击手势
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            print("🎯 DEBUG: handleTap 开始")
            
            guard let arView = gesture.view as? ARSCNView else {
                print("  ❌ 无法获取ARSCNView")
                return
            }
            
            let location = gesture.location(in: arView)
            print("  👆 点击位置: (\(location.x), \(location.y))")
            
            let hitTestResults = arView.hitTest(location, options: nil)
            print("  🎯 hitTest结果数量: \(hitTestResults.count)")
            
            for (index, result) in hitTestResults.enumerated() {
                print("    结果\(index): node=\(result.node), parentName=\(result.node.parent?.name ?? "nil")")
                
                // 检查是否点击了收集点节点或其子节点
                var targetNode = result.node
                var nodeId: String? = nil
                
                // 向上查找直到找到有名称的节点
                while nodeId == nil && targetNode.parent != nil {
                    if let name = targetNode.name, collectibleNodes[name] != nil {
                        nodeId = name
                        break
                    }
                    if let parentName = targetNode.parent?.name, collectibleNodes[parentName] != nil {
                        nodeId = parentName
                        break
                    }
                    targetNode = targetNode.parent!
                }
                
                if let nodeId = nodeId, let collectibleInfo = collectibleNodes[nodeId] {
                    print("  ✅ 点击了收集点: \(collectibleInfo.collectible.name)")
                    
                    // 触发收集动画
                    triggerCollectionAnimation(node: collectibleInfo.node)
                    
                    // 调用收集回调
                    DispatchQueue.main.async {
                        // 这里需要从coordinator传递回调，暂时先在这里处理
                        // onCollectionTapped(collectibleInfo.collectible)
                    }
                    
                    // 移除节点
                    collectibleNodes.removeValue(forKey: nodeId)
                    
                    break
                }
            }
            
            if hitTestResults.isEmpty {
                print("  ⚠️ 没有点击到任何3D对象")
            }
        }
        
        // 触发收集动画
        private func triggerCollectionAnimation(node: SCNNode) {
            print("🎯 DEBUG: triggerCollectionAnimation")
            
            // 停止之前的动画
            node.removeAllActions()
            
            // 收集成功动画：放大 -> 缩小消失
            let scaleUp = SCNAction.scale(to: 2.0, duration: 0.3)
            let scaleDown = SCNAction.scale(to: 0.1, duration: 0.4)
            let fadeOut = SCNAction.fadeOut(duration: 0.4)
            let remove = SCNAction.removeFromParentNode()
            
            let sequence = SCNAction.sequence([
                scaleUp,
                SCNAction.group([scaleDown, fadeOut]),
                remove
            ])
            
            node.runAction(sequence)
            print("  ✅ 收集动画开始")
        }
        
        // 以下是原有的导航相关方法（简化版）
        private func createDirectionArrow(arView: ARSCNView, instruction: NavigationInstruction) {
            let arrowGeometry = createArrowGeometry()
            arrowNode = SCNNode(geometry: arrowGeometry)
            
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemBlue
            material.emission.contents = UIColor.blue.withAlphaComponent(0.3)
            arrowGeometry.materials = [material]
            
            arrowNode?.position = SCNVector3(0, 1.5, -2)
            
            if let arrowNode = arrowNode {
                arView.scene.rootNode.addChildNode(arrowNode)
            }
        }
        
        private func createFloatingText(arView: ARSCNView, instruction: NavigationInstruction) {
            let textGeometry = SCNText(string: instruction.instruction, extrusionDepth: 0.02)
            textGeometry.font = UIFont.boldSystemFont(ofSize: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.5)
            
            textNode = SCNNode(geometry: textGeometry)
            textNode?.position = SCNVector3(-0.5, 2.2, -2)
            
            if let textNode = textNode {
                arView.scene.rootNode.addChildNode(textNode)
            }
        }
        
        private func createDistanceIndicator(arView: ARSCNView, instruction: NavigationInstruction) {
            let distanceText = SCNText(string: instruction.distance, extrusionDepth: 0.01)
            distanceText.font = UIFont.systemFont(ofSize: 0.08)
            distanceText.firstMaterial?.diffuse.contents = UIColor.systemGreen
            
            distanceNode = SCNNode(geometry: distanceText)
            distanceNode?.position = SCNVector3(-0.2, 1.0, -2)
            
            if let distanceNode = distanceNode {
                arView.scene.rootNode.addChildNode(distanceNode)
            }
        }
        
        private func createArrowGeometry() -> SCNGeometry {
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: 0, y: 0.3))
            arrowPath.addLine(to: CGPoint(x: -0.2, y: 0.1))
            arrowPath.addLine(to: CGPoint(x: -0.1, y: 0.1))
            arrowPath.addLine(to: CGPoint(x: -0.1, y: -0.3))
            arrowPath.addLine(to: CGPoint(x: 0.1, y: -0.3))
            arrowPath.addLine(to: CGPoint(x: 0.1, y: 0.1))
            arrowPath.addLine(to: CGPoint(x: 0.2, y: 0.1))
            arrowPath.close()
            
            return SCNShape(path: arrowPath, extrusionDepth: 0.05)
        }
        
        // MARK: - ARSCNViewDelegate
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            print("🎯 DEBUG: AR renderer didAdd node")
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR会话失败: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR会话被中断")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR会话中断结束")
        }
    }
}
