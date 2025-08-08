//
//  MapViewRepresentable.swift
//  HelloWorld
//
//  普通地图视图
//

import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: MKRoute?
    @Binding var startCoordinate: CLLocationCoordinate2D?
    @Binding var endCoordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
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
            
            let rect = route.polyline.boundingMapRect
            uiView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
        } else if let start = startCoordinate, let end = endCoordinate {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (start.latitude + end.latitude) / 2,
                    longitude: (start.longitude + end.longitude) / 2
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: abs(start.latitude - end.latitude) * 1.5 + 0.01,
                    longitudeDelta: abs(start.longitude - end.longitude) * 1.5 + 0.01
                )
            )
            uiView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
