//
//  ViewController.swift
//  IBMBlight
//
//  Created by Daniel T. Barwén on 2018-03-22.
//  Copyright © 2018 Daniel T. Barwén. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MessageUI

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, MFMailComposeViewControllerDelegate, MKMapViewDelegate {
    
    //------------------------------ Outlets and standard variables -------------------------------
    
    //Loadingscreen
    @IBOutlet weak var preScreen: UIView!
    
    //Main scrollView
    @IBOutlet weak var mainScrollview: UIScrollView!

    //Top mapView wrapper
    @IBOutlet weak var mainMapView: MKMapView!
    
    //CRV = cameraResultView
    @IBOutlet weak var cameraResultView: UIView!
    @IBOutlet weak var CRVheader: UILabel! //
    @IBOutlet weak var CRVsuggestedInfectionHeader: UILabel! //
    @IBOutlet weak var CRVsuggestedInfectionTypeValue: UILabel! //
    @IBOutlet weak var CRVprababilityHeader: UILabel! //
    @IBOutlet weak var CRVprobabilityDegreeValue: UILabel! //
    @IBOutlet weak var CRVstageHeader: UILabel! //
    @IBOutlet weak var CRVstageValue: UILabel! //
    @IBOutlet weak var CRVsendResult: UIButton! //
    @IBOutlet weak var CRVcloseBtn: UIButton!
    @IBOutlet weak var imageResultView: UIImageView!
    @IBOutlet weak var imageResultViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageResultViewTopConstraint: NSLayoutConstraint!
    
    
    
    //Alert view wrapper
    @IBOutlet weak var alertView: UIView!
    
    //Latest news wrapper
    @IBOutlet weak var newsView: UIView!
    
    //Height of the alertview
    @IBOutlet weak var alertViewHeightConstraint: NSLayoutConstraint!
    
    //Hegith of the newsView
    @IBOutlet weak var newsViewHeightConstraint: NSLayoutConstraint!
    
    
    var locationManager : CLLocationManager!
    
    //Base setup, GPS to IBM Malmö
    var localtion_lat = 55.611868
    var location_long = 12.977738
    
    //FakeLocation in CPX File
    //let initialLocation = CLLocation(latitude: 55.606118, longitude: 13.197447)
    //Fake farm 1
    var FF1_lat = 55.598424
    var FF1_long = 13.214542
    
    //Fake farm 2
    var FF2_lat = 55.584106
    var FF2_long = 13.214832
    
    //Fake farm 3
    var FF3_lat = 55.592145
    var FF3_long = 13.191919
    
    //Fake farm 4
    var FF4_lat = 55.606739
    var FF4_long = 13.196711
    
    //Mailadress user puts in befor sending the report
    var recipientValueMail : String = ""
    
    var todaysDate : String = ""
    
    var sendResultAlert = UIAlertController()
    
    var alertsBool = false
    var newsBool = false
    
    
    //Weather data Dark Sky API
    var forecastData = [Weather]()
    
    //------------------------------ Basics -------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        imageResultViewHeightConstraint.constant = 0
        imageResultViewTopConstraint.constant = 0
        imageResultView.isHidden = true
        locationManager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            //locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        moveMap()
        getCurrentDateTime()
        
    }
    
    //Changes the top statusbar to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            UIView.animate(withDuration: 0.7, animations: {
                self.preScreen.alpha = 0
            }, completion: nil)
        })
        
        //Preload last taken image and show it
        if UserDefaults.standard.value(forKey: "savedImage") == nil {
            print("NUPPNUPP")
        }else{
            print("JUPPJUPP")
            cameraResultView.dropShadowRemove()
            imageResultView.isHidden = false
            imageResultViewHeightConstraint.constant = 300
            imageResultViewTopConstraint.constant = 25
        
            CRVsetValuesText()
            
            let savedImage = UserDefaults.standard.object(forKey: "savedImage") as! NSData
            imageResultView.image = UIImage(data: savedImage as Data)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.cameraResultView.dropShadow()
            }
        }
        
        //imageResultView.transform = CGAffineTransform(rotationAngle: (180).pi)
        
        mainMapView.dropShadow()
        alertView.dropShadow()
        newsView.dropShadow()

        var myPin = OwnPin()
        myPin.title = "Hej"
        myPin.subtitle = "Tjena"
        myPin.coordinate = CLLocationCoordinate2D(latitude: FF1_lat, longitude: FF1_long)
        myPin.blight = true
        mainMapView.addAnnotation(myPin)
        
        var myPin2 = OwnPin()
        myPin2.title = "myPin2"
        myPin2.subtitle = "Wops"
        myPin2.coordinate = CLLocationCoordinate2D(latitude: FF2_lat, longitude: FF2_long)
        myPin2.blight = false
        mainMapView.addAnnotation(myPin2)
        
        mainMapView.isRotateEnabled = false
        updateWeatherForLocation(location: "New York")
    }
    
    //------------------------------ Map -------------------------------
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]
        localtion_lat = userLocation.coordinate.latitude
        location_long = userLocation.coordinate.longitude
        
        var myPinOwnPlace = OwnPin()
        myPinOwnPlace.title = "Hejsan popsan"
        myPinOwnPlace.subtitle = "subtitle"
        myPinOwnPlace.coordinate = CLLocationCoordinate2D(latitude: localtion_lat, longitude: location_long)
        myPinOwnPlace.blight = false
        mainMapView.addAnnotation(myPinOwnPlace)

        //moveMap()
    }
    
    func moveMap() {
        //let initialLocation = CLLocation(latitude: localtion_lat, longitude: location_long) //rätt sätt tillbaka sedan
        let initialLocation = CLLocation(latitude: 55.606118, longitude: 13.197447) // tempdata GPS
        let regionRadius: CLLocationDistance = 2500
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,regionRadius * 2.0, regionRadius * 2.0)
        mainMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? OwnPin {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            print(annotation.blight)
            if annotation.blight == true {
                view.pinTintColor = MKPinAnnotationView.redPinColor()
            } else {
                view.pinTintColor = MKPinAnnotationView.greenPinColor()
            }
            //view.pinTintColor = MKPinAnnotationView.greenPinColor()
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("calloutAccessoryControlTapped")
        
        let clickedAnnotation = view.annotation as! OwnPin
        if clickedAnnotation.title != nil {
            print(clickedAnnotation.title!)
        }
        
    }
    
    
    //I need to fix a couple of test annotations of diffrent farms. The data will be risklevel that will be checked in three % if else. One value that is my own and some other that is others
    //0 - 10% = green
    //10.1 - 50% = yellow
    //50.1 - 100% = red
    
    //------------------------------ Weather -----------------------------
    
    func updateWeatherForLocation (location:String) {
        CLGeocoder().geocodeAddressString(location) { (placemarks:[CLPlacemark]?, error:Error?) in
            if error == nil {
                if let location = placemarks?.first?.location {
                    var ownPin = OwnPin()
                    ownPin.coordinate = CLLocationCoordinate2D(latitude: 55.606118, longitude: 13.197447)
                    
                    Weather.forecast(withLocation: ownPin.coordinate, completion: { (results:[Weather]?) in
                        
                        if let weatherData = results {
                            print(self.forecastData.description)
                            self.forecastData = weatherData
                            let weatherObject = self.forecastData
                            //print(weatherObject.summary)
                            DispatchQueue.main.async {
                                
                                //self.tableView.reloadData()
                            }
                            
                        }
                        
                    })
                }
            }else{
                print(error.debugDescription)
            }
        }
    }
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        //let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//
//        let weatherObject = forecastData[indexPath.section]
//        print(weatherObject.summary)
//        //cell.textLabel?.text = weatherObject.summary
//        print("NUMERO 1")
//        switch weatherObject.windBearing {
//
//        case 0 ... 11:
//            print("Bearing : N - Speed : \(weatherObject.windSpeed) m/s")
//        case 11 ... 34:
//            print("Bearing : NNE - Speed : \(weatherObject.windSpeed) m/s")
//        case 34 ... 56:
//            print("Bearing : NE - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 56 ... 79:
//            print("Bearing : ENE - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 79 ... 101:
//            print("Bearing : E - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 101 ... 124:
//            print("Bearing : ESE - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 124 ... 146:
//            print("Bearing : SE - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 146 ... 169:
//            print("Bearing : SSE - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 169 ... 191:
//            print("Bearing : S - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 191 ... 214:
//            print("Bearing : SSW - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 214 ... 236:
//            print("Bearing : SW - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 236 ... 259:
//            print("Bearing : WSW - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 259 ... 281:
//            print("Bearing : W - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 281 ... 304:
//            print("Bearing : WNW - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 304 ... 326:
//            print("Bearing : NW - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 326 ... 349:
//            print("Bearing : NNW - Speed : \(weatherObject.windSpeed) m/s")
//
//        case 349 ... 360:
//            print("Bearing : N - Speed : \(weatherObject.windSpeed) m/s")
//
//        default:
//            print("failure")
//            print("The wind bearing is BULLSHIT)")
//        }
//
//        //cell.imageView?.image = UIImage(named: weatherObject.icon)
//        print("NUMERO 3")
//        //return cell
//    }
    
    
    //------------------------------ Camera -------------------------------

    @IBAction func getFromCamera(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.camera
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func getFromGallery(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageResultView.isHidden = false
        cameraResultView.dropShadowRemove()
        imageResultViewHeightConstraint.constant = 300
        imageResultViewTopConstraint.constant = 25
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        
        
        //Encode image for userDefaults
        let imageData : NSData = UIImagePNGRepresentation(pickedImage)! as NSData
        
        //Save image userDefaults
        UserDefaults.standard.set(imageData, forKey: "savedImage")
        
        //Decode image and display
        let activeImage = UserDefaults.standard.object(forKey: "savedImage") as! NSData
        imageResultView.image = UIImage(data: activeImage as Data)

        CRVsetValuesText()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.cameraResultView.dropShadow()
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    //------------------------------ Camera Result View -------------------------------
    
    func CRVsetValuesText(){
        CRVheader.text = "Result of analysis"
        CRVsuggestedInfectionHeader.text = "Suggested infection:"
        CRVsuggestedInfectionTypeValue.text = "infectionTypeValue"
        CRVprababilityHeader.text = "Propability of infection:"
        CRVprobabilityDegreeValue.text = "degreeValue"
        CRVstageHeader.text = "Stage of infection:"
        CRVstageValue.text = "stageValue"
        CRVsendResult.setTitle("Send result as email", for: .normal)
        CRVcloseBtn.setTitle("X", for: .normal)
    }
    
    func CRVresetValues() {
        CRVheader.text = ""
        CRVsuggestedInfectionHeader.text = ""
        CRVsuggestedInfectionTypeValue.text = ""
        CRVprababilityHeader.text = ""
        CRVprobabilityDegreeValue.text = ""
        CRVstageHeader.text = ""
        CRVstageValue.text = ""
        CRVsendResult.setTitle("", for: .normal)
        CRVcloseBtn.setTitle("", for: .normal)
    }
    
    
    @IBAction func CRVclose(_ sender: UIButton) {
        CRVresetValues()
        imageResultViewHeightConstraint.constant = 0
        imageResultViewTopConstraint.constant = 0
        cameraResultView.dropShadowRemove()
        imageResultView.isHidden = true
        UserDefaults.standard.set(nil, forKey: "savedImage")
    }
    
    @IBAction func CRVsendResult(_ sender: UIButton) {
        sendResultAlert = UIAlertController(title: "Clickydiclick", message: "this will open an email with the results, enter the recivers mailadress below", preferredStyle: .alert)
        
        sendResultAlert.addTextField { (textField) in
            textField.text = ""
        }
        sendResultAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        sendResultAlert.addAction(UIAlertAction(title: "Go", style: .default, handler: { [weak sendResultAlert] (_) in
            let textField = sendResultAlert!.textFields![0]
            if textField.text != "" {
                self.recipientValueMail = textField.text!
                
                let mailComposeViewController = self.configureMailController()
                if MFMailComposeViewController.canSendMail() {
                    self.present(mailComposeViewController, animated: true, completion: nil)
                } else {
                    self.showMailError()
                }
                
            } else {
                let noMailAdressAlert = UIAlertController(title: "No mailadress enterd", message: "Please enter a mailadress and try again", preferredStyle: .alert)
                noMailAdressAlert.addAction(UIAlertAction(title: "Alright", style: .default, handler: { [weak sendResultAlert] (_) in
                    self.present(sendResultAlert!, animated: true, completion: nil)
                }))
                self.present(noMailAdressAlert, animated: true, completion: nil)
                print("Bitch")
            }
            
        }))
        
        self.present(sendResultAlert, animated: true, completion: nil)
    }
    
    func configureMailController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        let image = imageResultView.image // Your Image
        let imageData = UIImagePNGRepresentation(image!) ?? nil
        let base64String = imageData?.base64EncodedString() ?? "" // Your String Image
        let mailImage = "<p><img src='data:image/png;base64,\(String(describing: base64String) )'></p>"
        
        mailComposerVC.setToRecipients(["\(recipientValueMail)"])
        mailComposerVC.setSubject("Result of analysis: \(todaysDate)")
        mailComposerVC.setMessageBody("<h2 style='color:#3271BB'>Hi</h2><h4>Here is the \(CRVheader.text!) from \(todaysDate)</h4><p>\(CRVsuggestedInfectionHeader.text!)</p><h6>\(CRVsuggestedInfectionTypeValue.text!)</h6></br><p>\(CRVprababilityHeader.text!)</p><h6>\(CRVsuggestedInfectionTypeValue.text!)</h6><p>\(CRVstageHeader.text!)</p><h6>\(CRVstageValue.text!)</h6></br><p>The picture that got this result is down below</p><p>Please get back to me, Best regards </br> \(mailImage)", isHTML: true)

        return mailComposerVC
    }
    
    //Fixing an errormessage if the sendMail function don't work
    func showMailError() {
        let sendMailErrorAlert = UIAlertController(title: "Could not send email", message: "Your device cound not send email, please check your settings", preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Ok", style: .default, handler: nil)
        sendMailErrorAlert.addAction(dismiss)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //------------------------------ Alerts View ( seperate viewController ) -----------------------------
    
    @IBAction func alertMoreClick(_ sender: UIButton) {
        if alertsBool == false {
            alertViewHeightConstraint.constant = 500
            alertView.dropShadowRemove()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.alertView.dropShadow()
            }
            alertsBool = true
        } else {
            alertViewHeightConstraint.constant = 250
            alertView.dropShadowRemove()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.alertView.dropShadow()
            }
            alertsBool = false
        }
    }
    
    
    //------------------------------ News View ( seperate viewController ) -------------------------------
    
    @IBAction func newsMoreClick(_ sender: UIButton) {
        if newsBool == false {
            newsViewHeightConstraint.constant = 500
            newsView.dropShadowRemove()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.newsView.dropShadow()
            }
            newsBool = true
        } else {
            newsViewHeightConstraint.constant = 250
            newsView.dropShadowRemove()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.newsView.dropShadow()
            }
            
            newsBool = false
        }
    }
    
    
    //------------------------------ Global -------------------------------
    
    //Get todays date
    func getCurrentDateTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        todaysDate = formatter.string(from: Date())
        print(todaysDate)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}




extension UIView {
    // OUTPUT 1
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowRadius = 5
        
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    // OUTPUT 2
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func dropShadowRemove(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 0
        
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}
