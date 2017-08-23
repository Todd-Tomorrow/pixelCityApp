//
//  ViewController.swift
//  pixelCity
//
//  Created by Todd Donnelly on 22/08/2017.
//  Copyright © 2017 Todd Donnelly. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    
    //outlets
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpViewHighConstraint: NSLayoutConstraint!
    
    //managers and instances
    var locationManager = CLLocationManager()
    //this is an inbuild check on authorisation
    let authorizationStatus = CLLocationManager.authorizationStatus()
    //1000 is 1000 feet
    let regionRadius: Double = 1000
    var screenSize = UIScreen.main.bounds
    var spinner: UIActivityIndicatorView?
    var progressLbl :UILabel?
    //start creating a programmatic collection view
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView:UICollectionView?
    
    //API work - create an empty array of strings for the URLS
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        //see below in the extension
        configureLocationServices()
        addDoubleTap()
        
        //instance of the collectionView with the reusable cell
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        pullUpView.addSubview(collectionView!)
    }

    func addDoubleTap(){                                                        //it will send doubleTap to dropPin()
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
        
    }
    
    func addSwipe(){
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    

    func animateViewUp(){
        //modify the constrain(of teh map view, so that you can move it)
        //mapViewBottomConstraint.constant = 300
        
        //OR
        
        //modify the hight constraint to make the view bigger
        pullUpViewHighConstraint.constant = 300
        //animate what comes next
        UIView.animate(withDuration: 0.3) {
            //redraw the new constraint
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown(){
        cancelAllSessions()
        pullUpViewHighConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner(){
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2)-((spinner?.frame.width)! / 2), y: 150) //150 is half of the 300 that we've set for the pull up view
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner(){
        if spinner != nil{
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl(){
        progressLbl = UILabel()                                        //25 points below the spinner
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 150, y: 175, width: 300, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        //progressLbl?.text = "1/16 PHOTOS LOADED"
        collectionView?.addSubview(progressLbl!)
        
    }
    
    func removeProgressLbl(){
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    //actions
    @IBAction func centreMapBtnWasPressed(_ sender: Any) {
        //if we have permission, centre the map on the user
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse{
            centerMapOnUserLocation()
        }
    }
    
    
    
//end of mapVC
}

//look up hte
extension MapVC: MKMapViewDelegate {
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //sets a special rule for MKuserLocation annonation (which is ignore it)
        if annotation is MKUserLocation {
            return nil
        }
        //then customise the other pin annotations
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager.location?.coordinate else {return}
        //sets a distance from a central coorindate
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //drop the pin on the map
    @objc func dropPin(sender: UITapGestureRecognizer){
        //remove Pins,spinners and progressLbl so only the new one will show canceldata session
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        //get the coordinates of the screen on doubleTap
        let touchPoint = sender.location(in: mapView)
        //convert into lat and lon cooridates
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        //annonations are Pins - DroppablePin is my view class,add it to the map
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        //create a new mapRegion around the touchCoordinate, then reload the map
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        //print FlickrAPI URL
        print(flickrURL(forApiKey: API_KEY, withAnnonation: annotation, addNumberOfPhotos: 40))
        
        //extend the view for photos
        animateViewUp()
        //add spinner and progress label
        addSpinner()
        addProgressLbl()
        //add the swipe action to dismiss this view when not needed
        addSwipe()
        retrieveUrls(forAnnotation: annotation) { (finished) in
            print(self.imageUrlArray)
            if finished {
                self.retrieveImages(handler: { (finished) in
                    if finished {
                        //hide spinner, label
                        self.removeSpinner()
                        self.removeProgressLbl()
                        //and reload collectionview
                    }
                })
            }
        }
    }
    
    func removePin() {
        // it s a for loop! remove all the annotions (so you can add the new one)
        for annonation in mapView.annotations {
            //never fails as usersLocation is also an unremoveable annonation :)
            mapView.removeAnnotation(annonation)
        }
    }
                                                                        //means that the result can escape the function and be used elsewhere
    func retrieveUrls(forAnnotation annotation:DroppablePin, handler: @escaping(_ status:Bool) -> () ){
        //clear previous loaded arrays
        imageUrlArray = []
        //Call the flickerAPIURL
        Alamofire.request(flickrURL(forApiKey: API_KEY, withAnnonation: annotation, addNumberOfPhotos: 40)).responseJSON { (response) in
            
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
            
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            
            for photo in photosDictArray {
                //create a user based on the flicker API response and flickstaticWebUrl structure
                // which is: https://farm8.staticflickr.com/7169/6717637369_0e43d11892_b_d.jpg
                // which is           farm               server/      id   _    secret_b_d.jpg
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                //append the URL to the imageURLArray
                self.imageUrlArray.append(postUrl)
            }
            //finish this process
            handler(true)
        }
        
    }
    
    
    func retrieveImages(handler:@escaping(_ status:Bool) ->()) {
        //clear out precious loaded images
        imageArray = []
        
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                //deal with the response
                guard let image = response.result.value else {return}
                self.imageArray.append(image)
                
                self.progressLbl?.text = "\(self.imageArray.count)/\(self.imageUrlArray.count) IMAGES DOWNLOADED"
                
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            })
        }
        
    }
    
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
            
        }
    }
    
    
    //end of MKMapViewDelegate
}

extension MapVC: CLLocationManagerDelegate {
   //is our app authorised if not request
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    //this allow the location manager to interact with the centremapOnUser WHEN correct authorisation has been given
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
    
}

//conform to the requirements of the UICOllectionView
extension MapVC:UICollectionViewDelegate, UICollectionViewDataSource{
    //number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    //content of items
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell
        return cell!
        
    }
}

