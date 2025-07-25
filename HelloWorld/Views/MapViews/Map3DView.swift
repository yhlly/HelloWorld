//
//  Map3DView.swift
//  HelloWorld
//
//  3D地图视图
//

import SwiftUI
import MapKit

struct Map3DView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: MKRoute?
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    @Binding var currentLocationIndex: Int
    let instructions: [NavigationInstruction]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        mapView.mapType = .standard
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        let camera = MKMapCamera()
        camera.centerCoordinate = region.center
        camera.altitude = 1000
        camera.pitch = 45
        mapView.setCamera(camera, animated: true)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        if let start = startCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "起点"
            uiView.addAnnotation(startAnnotation)
        }
        
        if let end = endCoordinate {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "终点"
            uiView.addAnnotation(endAnnotation)
        }
        
        if let route = route {
            uiView.addOverlay(route.polyline)
        }
        
        for (index, instruction) in instructions.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = instruction.coordinate
            annotation.title = "步骤 \(index + 1)"
            annotation.subtitle = instruction.instruction
            uiView.addAnnotation(annotation)
        }
        
        if currentLocationIndex < instructions.count {
            let currentInstruction = instructions[currentLocationIndex]
            let camera = MKMapCamera()
            camera.centerCoordinate = currentInstruction.coordinate
            camera.altitude = 500
            camera.pitch = 60
            uiView.setCamera(camera, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: Map3DView
        
        init(_ parent: Map3DView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 8
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "NavigationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .systemBlue
                markerView.glyphText = "🧭"
            }
            
            return annotationView
        }
    }
}
