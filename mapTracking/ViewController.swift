//
//  ViewController.swift
//  mapTracking
//
//  Created by omarmattr on 17/01/2022.
//

import UIKit
import GoogleMaps

var locationUpdateCls: ((CLLocation)->())?
var polyLineUpdate: ((GMSPolyline)->())?
// GeeksforGeeks coordinates
private var originLatitude: Double = 28.5021359
private var originLongitude: Double = 77.4054901
  
// Coordinates of a park nearby
private var destinationLatitude: Double = 28.5151087
private var destinationLongitude: Double = 77.3932163
class ViewController: UIViewController {

    private var polyline = GMSPolyline(path: GMSPath(fromEncodedPath: "{dq_IowzpAzkAbhF"))

    override func viewDidLoad() {
        super.viewDidLoad()
        // coordinate -33.86,151.20 at zoom level 6.
        let camera = GMSCameraPosition.camera(withLatitude: originLatitude, longitude: originLongitude, zoom: 16.0)
        
            let mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
            self.view.addSubview(mapView)

            // Creates a marker in the center of the map.
            let marker = GMSMarker()
            marker.icon = #imageLiteral(resourceName: "car")
            marker.title = "Sydney"
            marker.snippet = "Australia"
            marker.map = mapView
        
      //  let strokeStyles = [GMSStrokeStyle.solidColor(.black), GMSStrokeStyle.solidColor(.clear)]
      //  let strokeLengths = [NSNumber(value: 10), NSNumber(value: 10)]
     //   if let path = polyline.path {
       //   polyline.spans = GMSStyleSpans(path, strokeStyles, strokeLengths, .rhumb)
        //}
        polyline.map = mapView
        mapView.delegate = self
       
       set(polyline: polyline, on: mapView)
//       fetchRoute(from: CLLocationCoordinate2D(latitude: originLatitude, longitude: originLongitude), to: CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude))
        draw(src: CLLocationCoordinate2D(latitude: originLatitude, longitude: originLongitude), dst:  CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude))

        locationUpdateCls = { location in

         //   self.moveBike(map: mapView, marker: marker, location: location.coordinate)
        }
        polyLineUpdate = {poly in
            self.set(polyline: poly, on: mapView)
        }


    }
    func moveBike(map:GMSMapView,marker : GMSMarker,location:CLLocationCoordinate2D){
        
        let bearing = getBearingBetweenTwoPoints1(point1: marker.position, point2: location)
        CATransaction.begin()
        CATransaction.setAnimationDuration (2.0)
        marker.position = location
        marker.rotation = bearing
        CATransaction.commit ()
        let camera = GMSCameraPosition(latitude: location.latitude, longitude: location.longitude, zoom:
                                        map.camera.zoom)
        map.animate(to: camera)
        }
    func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let x1 = from.longitude * (Double.pi / 180.0)
        let y1 = from.latitude * (Double.pi / 180.0)
        let x2 = to.longitude * (Double.pi / 180.0)
        let y2 = to.latitude * (Double.pi / 188.0)
                                 
                            
        let dx = x2 - x1
        let sita = atan2 (sin(dx) * cos (y2), cos (y1) * sin(y2) - sin(y1) * cos(y2) * cos (dx))
        return sita * (180.0 / Double.pi)

}
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }

    func getBearingBetweenTwoPoints1(point1 : CLLocationCoordinate2D, point2 : CLLocationCoordinate2D) -> Double {

        let lat1 = degreesToRadians(degrees: point1.latitude)
        let lon1 = degreesToRadians(degrees: point1.longitude)

        let lat2 = degreesToRadians(degrees: point2.latitude)
        let lon2 = degreesToRadians(degrees: point2.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansToDegrees(radians: radiansBearing)
    }
    private func set(polyline: GMSPolyline, on mapView: GMSMapView) {
            guard let path = polyline.path else {
                return
            }
            mapView.clear()
            let intervalDistanceIncrement: CGFloat = 10
            let circleRadiusScale = 1 / mapView.projection.points(forMeters: 1, at: mapView.camera.target)
            var previousCircle: GMSCircle?
        print(path.count())
            for coordinateIndex in 0 ..< path.count() - 1 {
                let startCoordinate = path.coordinate(at: coordinateIndex)
                let endCoordinate = path.coordinate(at: coordinateIndex + 1)
                let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
                let endLocation = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
                let pathDistance = endLocation.distance(from: startLocation)
                let intervalLatIncrement = (endLocation.coordinate.latitude - startLocation.coordinate.latitude) / pathDistance
                let intervalLngIncrement = (endLocation.coordinate.longitude - startLocation.coordinate.longitude) / pathDistance
                for intervalDistance in 0 ..< Int(pathDistance) {
                    let intervalLat = startLocation.coordinate.latitude + (intervalLatIncrement * Double(intervalDistance))
                    let intervalLng = startLocation.coordinate.longitude + (intervalLngIncrement * Double(intervalDistance))
                    let circleCoordinate = CLLocationCoordinate2D(latitude: intervalLat, longitude: intervalLng)
                    if let previousCircle = previousCircle {
                        let circleLocation = CLLocation(latitude: circleCoordinate.latitude,
                                                        longitude: circleCoordinate.longitude)
                        let previousCircleLocation = CLLocation(latitude: previousCircle.position.latitude,
                                                                longitude: previousCircle.position.longitude)
                        if mapView.projection.points(forMeters: circleLocation.distance(from: previousCircleLocation),
                                                     at: mapView.camera.target) < intervalDistanceIncrement {
                            continue
                        }
                    }
                    let circleRadius = 3 * CLLocationDistance(circleRadiusScale)
                    let circle = GMSCircle(position: circleCoordinate, radius: circleRadius)
                    
                    circle.fillColor = #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)
                    circle.map = mapView
                    previousCircle = circle
                }
            }
        }
}
extension ViewController:GMSMapViewDelegate{
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
      //  set(polyline: polyline, on: mapView)
    }

}
extension ViewController{
    func fetchRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        
        let session = URLSession.shared
        
        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&key=AIzaSyBAu5e3Lqm2RfIlwHxxdnwc7N0dmERxl")!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            print("kkkkkkkkkkk1")
            guard error == nil else {
                print("pppppppp\(error!.localizedDescription)")
                return
            }
            print("kkkkkkkkkkk2")
            guard let jsonResult = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] else {
                print("error in JSONSerialization")
                return
            }
            print("kkkkkkkkkkk3")
            guard let routes = jsonResult["routes"] as? [Any] else {
                return
            }
            print("kkkkkkkkkkk4")
            guard  !routes.isEmpty , let route = routes[0] as? [String: Any] else {
                return
            }
            print("kkkkkkkkkkk5")
            guard let overview_polyline = route["overview_polyline"] as? [String: Any] else {
                return
            }
            print("kkkkkkkkkkk")
            guard let polyLineString = overview_polyline["points"] as? String else {
                return
            }
            
            //Call this method to draw path on map
          //  self.drawPath(from: polyLineString)
            print("kkkkkkkkkkk")
            let path = GMSPath(fromEncodedPath: polyLineString)
            self.polyline = GMSPolyline(path: path)
        })
        task.resume()
    }
//    func drawPath(from polyStr: String){
//        let path = GMSPath(fromEncodedPath: polyStr)
//        let polyline = GMSPolyline(path: path)
//        polyline.strokeWidth = 3.0
//        polyline.map = mapView // Google MapView
//
//
//        let cameraUpdate = GMSCameraUpdate.fit(GMSCoordinateBounds(coordinate: sourceLocationCordinates, coordinate: destinationLocationCordinates))
//        mapView.moveCamera(cameraUpdate)
//        let currentZoom = mapView.camera.zoom
//        mapView.animate(toZoom: currentZoom - 1.4)
//    }
    func draw(src: CLLocationCoordinate2D, dst: CLLocationCoordinate2D){

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(src.latitude),\(src.longitude)&destination=\(dst.latitude),\(dst.longitude)&sensor=false&mode=walking&key=AIzaSyBAu5e3Lqm2RfIlwHxxdnwc7N0dmERxl-c")!

        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                do {
                    if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] {

                        let preRoutes = json["routes"] as! NSArray
                        json.forEach { ii in
                            print(ii)
                        }
                        let routes = preRoutes[0] as! NSDictionary
                        let routeOverviewPolyline:NSDictionary = routes.value(forKey: "overview_polyline") as! NSDictionary
                        let polyString = routeOverviewPolyline.object(forKey: "points") as! String

                        DispatchQueue.main.async(execute: {
                            let path = GMSPath(fromEncodedPath: polyString)
                            guard let poly = polyLineUpdate else {
                                return
                            }
                            poly(GMSPolyline(path: path))

                        })
                    }

                } catch {
                    print("parsing error")
                }
            }
        })
        task.resume()

    }
    
}

