//
//  InterfaceController.swift
//  FourZone4Blueprint WatchKit Extension
//
//  Created by Ilia Tikhomirov on 28/02/16.
//  Copyright © 2016 Ilia Tikhomirov. All rights reserved.
//

import Foundation
import HealthKit
import WatchKit



class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    @IBOutlet var statusView: WKInterfaceLabel!
    @IBOutlet var ringView: WKInterfaceImage!
    @IBOutlet var percentageView: WKInterfaceLabel!
    @IBOutlet var bpmVIew: WKInterfaceLabel!
    
    let healthStore = HKHealthStore()
    var i = 0
    var workoutActive = false
    var workoutSession : HKWorkoutSession?
    let heartRateUnit = HKUnit(fromString: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))

  // var hardData = [60.0,70.0,63.0,76.0,68.0,62.0,78.0,84.0,75.0,61.0,65.0,78.0]

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        print(context)
        
        // Configure interface objects here.
        
        ringView.setImageNamed("Light")
        
        switch context as! String {
            
        case "Hardcore":
        //    self.hardData = [135.0,143.0,153.0,158.0,150.0,152.0,149.0,152.0,156.0,158.0,146.0,142.0]
            ringView.startAnimatingWithImagesInRange(NSMakeRange(0, 37), duration: 2, repeatCount: 1)
            percentageView.setText("96%")
            statusView.setText("DANGEROUS HR")
            
            
        case "Fat Burning":
            
            ringView.startAnimatingWithImagesInRange(NSMakeRange(0, 27), duration: 1, repeatCount: 1)
            percentageView.setText("70%")
            statusView.setText("Fat burning")

            
        case "Endurance":
          //  self.hardData = [90.0,98.0,103.0,98.0,95.0,97.0,101.0,106.0,109.0,96.0,98.0,101.0]
            ringView.startAnimatingWithImagesInRange(NSMakeRange(0, 23), duration: 1, repeatCount: 1)
            percentageView.setText("65%")
            statusView.setText("Longer...")

            
        case "Walk and Chill":
            
            ringView.startAnimatingWithImagesInRange(NSMakeRange(0, 14), duration: 1, repeatCount: 1)
            percentageView.setText("45%")
            statusView.setText("Relax...")

            
        default:
            
            print("Non")

            
        }
        
        startBtnTapped()
        var timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "update", userInfo: nil, repeats: true)
        
    }
    
    

        func update() {
        bpmVIew.setText(String(HRRealVal) + " bpm")
        setUpCircles(Double(HRRealVal))
        
        i++
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        startBtnTapped()
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        switch toState {
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        // Do nothing for now
        NSLog("Workout error: \(error.userInfo)")
    }
    
    func workoutDidStart(date : NSDate) {
        print("Workout did start")
        if let query = createHeartRateStreamingQuery(date) {
            print("Using query")
            healthStore.executeQuery(query)
            
        } else {
            print("cannot start")
        }
    }
    
    func workoutDidEnd(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.stopQuery(query)
        } else {
            //label.setText("cannot stop")
        }
    }
    
    // MARK: - Actions
    func startBtnTapped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
     //       self.startStopButton.setTitle("Start")
            print("Finishing Workout")

            if let workout = self.workoutSession {
                healthStore.endWorkoutSession(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
       //     self.startStopButton.setTitle("Stop")
            startWorkout()
            
            print("Starting Workout")
        }
        
    }
    
    func startWorkout() {
        self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
        self.workoutSession?.delegate = self
        healthStore.startWorkoutSession(self.workoutSession!)
    }
    
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        // adding predicate will not work
        
        let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        print("Entered queury")
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil }
    
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
           // guard let newAnchor = newAnchor else {return}
           // self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
            print("Query is configured")
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
           // self.anchor = newAnchor!
            self.updateHeartRate(samples)
            print("Updating sample")
            print(samples)
        }
        return heartRateQuery
    }

    
    func updateHeartRate(samples: [HKSample]?) {
        print("Entered updateHR")
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            
            print("No HR detected")
            
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            print("Enter async")
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            print(String(UInt16(value)))
            //HERE IS THE VALUE
            self.HRRealVal = Int(value)
            
            // retrieve source from sample
            print(sample.sourceRevision.source.name)

        }
    }
    
    var HRRealVal: Int = 0
    
    var workoutType: String = "Walk and Chill"
    func setUpCircles(bpm: Double){
        let AGE = 18
        let percent = bpm / (Double)(220 - AGE) * 100
        if(percent <= 90){
            setupBlueView(percent / 80 * 100)
        }
        else{
            setupOverloadView()
        }
        checkForWarning(percent, workoutType: self.workoutType)
    }
    func setupBlueView(percent: Double){
        let segFilled: Double = percent / 100 * 36
        ringView.startAnimatingWithImagesInRange(NSMakeRange(0, (Int)(segFilled)), duration: 1, repeatCount: 1)
    }
    
    func setupOverloadView(){
        ringView.startAnimatingWithImagesInRange(NSMakeRange(0, (Int)(37)), duration: 1, repeatCount: 1)
    }
    
    
    func checkForWarning(percent: Double, workoutType: String){
        //Light <60
        //Fat 60 to 70
        //70 to 90 endurance
        //90+ DANGER
        if(percent > 95){
            WKInterfaceDevice.currentDevice().playHaptic(.Failure)
        }
        else{
            switch workoutType{
            case "Walk and Chill":
                //always good
                break
                
            case "Fat Burn":
                if(percent < 60){
                    //Hurry Up
                    WKInterfaceDevice.currentDevice().playHaptic(.Success)
                }
                else if(percent > 70){
                    //too fast
                    WKInterfaceDevice.currentDevice().playHaptic(.Notification)
                }
            case "Endurance":
                if(percent < 70){
                    //Hurry Up
                    WKInterfaceDevice.currentDevice().playHaptic(.Success)
                }
                else if(percent > 90){
                    //too fast
                    WKInterfaceDevice.currentDevice().playHaptic(.Notification)
                }
                
                
            case "Overload":
                if(percent < 90){
                    //Hurry Up
                    WKInterfaceDevice.currentDevice().playHaptic(.Success)
                }
                default:print("crap")
            }
            
        }
    }
    
    
   }



