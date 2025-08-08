//
//  LocationSearchManager.swift
//  ScenePath
//
//  位置搜索管理器
//

import Foundation
import MapKit
import Combine

class LocationSearchManager: NSObject, ObservableObject {
    @Published var suggestions: [LocationSuggestion] = []
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestions.removeAll()
            return
        }
        
        isSearching = true
        searchCompleter.queryFragment = query
    }
    
    func clearSuggestions() {
        suggestions.removeAll()
        isSearching = false
    }
    
    func getCoordinate(for suggestion: LocationSuggestion, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard let searchCompletion = suggestion.completion else {
            completion(suggestion.coordinate)
            return
        }
        
        let searchRequest = MKLocalSearch.Request(completion: searchCompletion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            DispatchQueue.main.async {
                completion(response?.mapItems.first?.placemark.coordinate)
            }
        }
    }
}

extension LocationSearchManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results.map { completion in
                LocationSuggestion(
                    title: completion.title,
                    subtitle: completion.subtitle,
                    coordinate: nil,
                    completion: completion
                )
            }
            self.isSearching = false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            print("Search completer error: \(error.localizedDescription)")
        }
    }
}
