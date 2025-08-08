# ScenePath

ScenePath is an iOS application that combines augmented reality (AR) with navigation to provide an immersive route planning and exploration experience. The app allows users to discover interesting locations in their journey through experiencing specialized routes, collecting stamps and following map guides with AR.

## Features

- **Specialized Routes**: Discover scenic paths, food spots, or interesting places during your journey
- **Route Simulation**: Preview and simulate your route before actually traveling
- **Augmented Reality Navigation**: Experience directions in AR which are more visual
- **Collection System**: Collect stamps in special routes

## Technologies Used

- Swift
- SwiftUI
- SwiftData
- MapKit
- ARKit
- SceneKit
- CoreLocation

## Requirements

- iOS 18.5+
- Xcode Beta Version

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yhlly/ScenePath.git
   ```

2. Open the project in Xcode:
   ```bash
   cd ScenePath
   open ScenePath.xcodeproj
   ```

3. Select your development team in the project settings.

4. Build and run the application on your iOS device.

## Usage Guide

### Getting Started

1. **Launch the App**: Open ScenePath on your iOS device.
2. **Enter Locations**: Input your starting point and destination. You can use "My Location" for your current position.
3. **Choose a Route Preference**: Select between standard routes, scenic routes, food routes, or attraction routes.
4. **Select Transportation Type**: Choose between walking, driving, or public transport(still developing).
5. **View Routes**: Review the suggested routes and select one to preview.

### Route Simulation

- Watch a simulation of your route before actually traveling
- Click on the angle and you can go ahead or turn back

### AR Navigation

- Experience AR navigation with directional arrows and instructions
- Collect items along special routes

### Collections

- Access your collection through the bag icon
- View all collected items organized by category

## Project Structure

```
ScenePath/
├── ContentView.swift               
├── ScenePathApp.swift               
├── Managers/
│   ├── RouteSimulationPlayer.swift   
│   ├── CollectionManager.swift       
│   ├── LocationSearchManager.swift  
│   └── LocationManager.swift        
├── Models/
│   ├── AppState.swift              
│   ├── NavigationModels.swift        
│   ├── CollectibleItem.swift        
│   ├── TransportationType.swift     
│   ├── RouteType.swift             
│   └── SpecialRouteType.swift        
├── Extensions/
│   └── CLLocationCoordinate2D+Extensions.swift  
├── Views/
│   ├── CollectionView.swift       
│   ├── ARNavigationView.swift   
│   ├── RoutePreviewView.swift        
│   ├── SearchRouteView.swift        
│   ├── Components/
│   │   ├── SpecialRouteSelector.swift    
│   │   ├── CollectibleMapOverlay.swift   
│   │   ├── TransportTab.swift            
│   │   ├── EnhancedLocationSearchBar.swift 
│   │   └── RouteCard.swift             
│   └── MapViews/
│       ├── EnhancedARNavigationView.swift 
│       ├── RouteSimulationView.swift      
│       ├── MapViewRepresentable.swift     
│       ├── ARNavigationMapView.swift      
│       └── EnhancedARSceneView.swift      
└── Services/
    └── RouteService.swift           
```
