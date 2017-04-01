//
//  ViewController.swift
//  HiBeacons
//
//  Created by bluekey630 on 4/1/17.
//  Copyright © 2017 bluekey630. All rights reserved.
//
import Foundation
import UIKit
import CoreLocation
import UserNotifications
import WatchConnectivity
import CoreTelephony

class ViewController: UIViewController {

    @IBOutlet weak var beaconTableView: UITableView!
    
    
    // Constants
    
    /// The maximum number of table view sections (when ranged beacons are included).
    let kMaxNumberOfSections = 2
    /// The number of possible operations.
    let kNumberOfAvailableOperations = 3
    
    /// The title for the beacon ranging table view section.
    let kBeaconSectionTitle = "Ranging for beacons..."
    /// The position of the activity indicator in the ranging table view header.
    let kActivityIndicatorPosition = CGPoint(x: 205, y: 12)
    /// The identifier for the beacon ranging table view header.
    let kBeaconsHeaderViewIdentifier = "BeaconsHeader"
    
    
    /// The monitoring operation state.
    var monitoringActive = false {
        didSet {
            if monitoringActive != oldValue {
                monitoringSwitch.setOn(monitoringActive, animated: true)
            }
        }
    }
    
    /// The advertising operation state.
    var advertisingActive = false {
        didSet {
            if advertisingActive != oldValue {
                advertisingSwitch.setOn(advertisingActive, animated: true)
            }
        }
    }
    
    /// The ranging operation state.
    var rangingActive = false {
        didSet {
            if rangingActive != oldValue {
                rangingSwitch.setOn(rangingActive, animated: true)
            }
        }
    }
    
    
    // Enumerations
    
    /// Used for representing the type of the table view section.
    enum NATSectionType: Int
    {
        /// Represents the first section, that contains the cells that can perform operations, and have switches.
        case operations = 0
        
        /// Represents the second section, that lists cells, each with a ranged beacon.
        case detectedBeacons
        
        /// Returns the table view cell identifier that corresponds to the section type.
        func cellIdentifier() -> String {
            switch self {
            case .operations:
                return "OperationCell"
            case .detectedBeacons:
                return "BeaconCell"
            }
        }
        
        /// Returns the table view cell height that corresponds to the section type.
        func tableViewCellHeight() -> CGFloat {
            switch self {
            case .operations:
                return 44.0
            case .detectedBeacons:
                return 52.0
            }
        }
    }
    
    
    // The Operation objects
    
    /// The monitoring operation object.
    let monitoringOperation = NATMonitoringOperation()
    /// The advertising operation object.
    let advertisingOperation = NATAdvertisingOperation()
    /// The ranging operation object.
    let rangingOperation = NATRangingOperation()
    
    
    // Other
    
    /// An array of CLBeacon objects, typically those detected through ranging.
    var detectedBeacons = [CLBeacon]()
    
    /// The UISwitch instance associated with the monitoring cell.
    var monitoringSwitch: UISwitch!
    /// The UISwitch instance associated with the advertising cell.
    var advertisingSwitch: UISwitch!
    /// The UISwitch instance associated with the ranging cell.
    var rangingSwitch: UISwitch!
    
    /// The UIActivityIndicatorView that shows whether monitoring is active.
    var monitoringActivityIndicator: UIActivityIndicatorView!
    /// The UIActivityIndicatorView that shows whether advertising is active.
    var advertisingActivityIndicator: UIActivityIndicatorView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // We need to assign self as a delegate here.
        monitoringOperation.delegate = self
        advertisingOperation.delegate = self
        rangingOperation.delegate = self
    }
    var locationManager: CLLocationManager?
    /// The main WCSession instance
    var mainSession: WCSession?

    var callCenter: CTCallCenter?
    var isCalling = false
    var count = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.callCenter = CTCallCenter()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// Sets up the default WCSession instance.
    override func viewDidAppear(_ animated: Bool) {
        if WCSession.isSupported() {
            mainSession = WCSession.default()
            mainSession!.delegate = self
            mainSession!.activate()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(makeCall1), name: NSNotification.Name(rawValue: "call"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(suspended), name: NSNotification.Name(rawValue: "UIApplicationSuspendedNotification"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "call"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UIApplicationSuspendedNotification"), object: nil)
        
    }


}

// MARK: - Index path management
extension ViewController
{
    /**
     Returns an array of NSIndexPath instances for the given beacons, which are to be removed from the table view.
     Not all of the given beacons will actually be removed. It will be determined by comparing with the currently
     detected beacons.
     :param: beacons An array of CLBeacon objects.
     :returns: An array of NSIndexPaths corresponding to positions in the table view where these beacons are.
     */
    func handleCall() {
        self.callCenter?.callEventHandler = {(call: CTCall) -> () in
            
            if call.callState == CTCallStateConnected {
                print("call CTCallStateConnected")
            }
            else if call.callState == CTCallStateDialing {
                print("call CTCallStateDialing")
            }
            else if call.callState == CTCallStateDisconnected {
                print("call CTCallStateDisconnected")
            }
            else if call.callState == CTCallStateIncoming {
                print("call CTCallStateIncoming")
            }
            
        }
    }

    func suspended()//_ notification:NSNotification)//(NSNotification *) notification
    {
        print("Suspended")
    }
    
    func makeCall()
    {
        let phoneNumberURL = NSURL(string:"telprompt://119");
        let app = UIApplication.shared
        app.openURL(phoneNumberURL as! URL)
    }
    
    func makeCall1()
    {
        count = 9;
    }
    
    func sendLocalNotificationForBeaconRegion(region: CLBeaconRegion)
    {
        let notification = UILocalNotification();
        
        // Notification details
        notification.alertBody = String(format:"UUID: %@",
                                        region.proximityUUID.uuidString)   // Major and minor are not available at the monitoring stage
        notification.alertAction = NSLocalizedString("Beacon Found", comment:"")
        notification.soundName = UILocalNotificationDefaultSoundName
        
        //[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        UIApplication.shared.scheduleLocalNotification(notification)
    }

    
    func createLocationManager()
    {
        if (self.locationManager == nil) {
            self.locationManager = CLLocationManager()
            self.locationManager?.allowsBackgroundLocationUpdates = true;
            self.locationManager?.delegate = self;
            self.locationManager?.startUpdatingLocation();
        }
    }
    
    func indexPathsOfRemovedBeacons(_ beacons: [CLBeacon]) -> [IndexPath]? {
        var indexPaths: [IndexPath]?
        
        var row = 0
        for existingBeacon in detectedBeacons {
            var stillExists = false
            for beacon in beacons {
                if existingBeacon.major.intValue == beacon.major.intValue && existingBeacon.minor.intValue == beacon.minor.intValue {
                    stillExists = true
                    break
                }
            }
            
            if stillExists == false {
                indexPaths = indexPaths ?? []
                indexPaths!.append(IndexPath(row: row, section: NATSectionType.detectedBeacons.rawValue))
            }
            row += 1
        }
        
        return indexPaths
    }
    
    /**
     Returns an array of NSIndexPath instances for the given beacons, which are to be inserted in the table view.
     Not all of the given beacons will actually be inserted. It will be determined by comparing with all the
     currently detected beacons.
     :param: beacons An array of CLBeacon objects.
     :returns: An array of NSIndexPaths corresponding to positions in the table view where these beacons are.
     */
    func indexPathsOfInsertedBeacons(_ beacons: [CLBeacon]) -> [IndexPath]? {
        var indexPaths: [IndexPath]?
        
        var row = 0
        for beacon in beacons {
            var isNewBeacon = true
            for existingBeacon in detectedBeacons {
                if existingBeacon.major.intValue == beacon.major.intValue && existingBeacon.minor.intValue == beacon.minor.intValue {
                    isNewBeacon = false
                    break
                }
            }
            
            if isNewBeacon == true {
                indexPaths = indexPaths ?? []
                indexPaths!.append(IndexPath(row: row, section: NATSectionType.detectedBeacons.rawValue))
            }
            row += 1
        }
        
        return indexPaths
    }
    
    /**
     Returns an array of NSIndexPath instances for the given beacons.
     :param: beacons An array of CLBeacon objects.
     */
    func indexPathsForBeacons(_ beacons: [CLBeacon]) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        
        for row in 0..<beacons.count {
            indexPaths.append(IndexPath(row: row, section: NATSectionType.detectedBeacons.rawValue))
        }
        
        return indexPaths
    }
    
    /// Returns an NSIndexSet instance of the inserted sections in the table view or nil.
    func insertedSections() -> IndexSet? {
        if rangingActive == true && beaconTableView.numberOfSections == kMaxNumberOfSections - 1 {
            return IndexSet(integer: 1)
        } else {
            return nil
        }
    }
    
    /// Returns an NSIndexSet instance of the deleted sections in the table view or nil.
    func deletedSections() -> IndexSet? {
        if rangingActive == false && beaconTableView.numberOfSections == kMaxNumberOfSections {
            return IndexSet(integer: 1)
        } else {
            return nil
        }
    }
    
    /**
     Returns an array of CLBeacon instances that has been all its duplicates filtered out.
     Duplicates may appear during ranging; this may happen temporarily if the originating device changes its
     Bluetooth ID.
     :param: beacons An array of CLBeacon objects.
     */
    func filteredBeacons(_ beacons: [CLBeacon]) -> [CLBeacon] {
        var filteredBeacons = beacons   // Copy
        
        var lookup = Set<String>()
        for index in 0..<beacons.count {
            let currentBeacon = beacons[index]
            let identifier = "\(currentBeacon.major)/\(currentBeacon.minor)"
            
            if lookup.contains(identifier) {
                filteredBeacons.remove(at: index)
            } else {
                lookup.insert(identifier)
            }
        }
        
        return filteredBeacons
    }
}

// MARK: - Table view functionality
extension ViewController: UITableViewDataSource, UITableViewDelegate
{
    /// Returns the right cell view for the given index path.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = NATSectionType(rawValue: (indexPath as NSIndexPath).section)?.cellIdentifier()
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier!)
        
        switch (indexPath as NSIndexPath).section {
        case NATSectionType.operations.rawValue:
            let operationCell = cell as! NATOperationCell
            cell?.textLabel?.text = NATOperationType(index: (indexPath as NSIndexPath).row)?.capitalizedRawValue()
            
            switch (indexPath as NSIndexPath).row {
            case NATOperationType.monitoring.index():
                monitoringSwitch = operationCell.accessoryView as? UISwitch
                monitoringActivityIndicator = operationCell.activityIndicator
                monitoringSwitch.addTarget(self, action: #selector(changeMonitoringState), for: UIControlEvents.valueChanged)
            case NATOperationType.advertising.index():
                advertisingSwitch = operationCell.accessoryView as? UISwitch
                advertisingActivityIndicator = operationCell.activityIndicator
                advertisingSwitch.addTarget(self, action: #selector(changeAdvertisingState), for: UIControlEvents.valueChanged)
            case NATOperationType.ranging.index():
                rangingSwitch = cell?.accessoryView as? UISwitch
                rangingSwitch.addTarget(self, action: #selector(changeRangingState), for: UIControlEvents.valueChanged)
            default:
                break
            }
        case NATSectionType.detectedBeacons.rawValue:
            let beacon = detectedBeacons[(indexPath as NSIndexPath).row]
            
            cell = cell ?? UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellIdentifier)
            
            cell!.textLabel?.text = beacon.proximityUUID.uuidString
            cell!.detailTextLabel?.text = beacon.fullDetails()
            cell!.detailTextLabel?.textColor = UIColor.gray
        default:
            break
        }
        
        // We wouldn't normally need this, since constraints can be set in Interface Builder. However, there seems
        // to be a bug that removes all constraints from our cells upon dequeueing, so we need to trigger re-adding
        // them here. (See also NATOperationCell.swift).
        cell?.updateConstraintsIfNeeded()
        
        return cell!
    }
    
    /// Returns the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        if rangingSwitch?.isOn == true {
            return kMaxNumberOfSections            // All sections visible
        } else {
            return kMaxNumberOfSections - 1        // Beacons section not visible
        }
    }
    
    /// Returns the number of rows for the section with the given index.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case NATSectionType.operations.rawValue:
            return kNumberOfAvailableOperations
        case NATSectionType.detectedBeacons.rawValue:
            return self.detectedBeacons.count
        default:
            return 0
        }
    }
    
    /// Returns the header title for a given section index.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case NATSectionType.operations.rawValue:
            return nil
        case NATSectionType.detectedBeacons.rawValue:
            return kBeaconSectionTitle
        default:
            return nil
        }
    }
    
    /// Returns the height for a given row index.
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NATSectionType(rawValue: (indexPath as NSIndexPath).section)!.tableViewCellHeight()
    }
    
    /// Returns the header view for a given section index.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView(reuseIdentifier: kBeaconsHeaderViewIdentifier)
        
        // Adds an activity indicator view to the section header
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        headerView.addSubview(indicatorView)
        indicatorView.frame = CGRect(origin: kActivityIndicatorPosition, size: indicatorView.frame.size)
        indicatorView.startAnimating()
        
        return headerView
    }
}

// MARK: - Operation methods
extension ViewController
{
    /// Changes the monitoring operation state, according to the switch's value.
    func changeMonitoringState() {
        monitoringActive = monitoringSwitch.isOn
        updateMonitoringState()
    }
    
    /// Changes the advertising operation state, according to the switch's value.
    func changeAdvertisingState() {
        advertisingActive = advertisingSwitch.isOn
        updateAdvertisingState()
    }
    
    /// Changes the ranging operation state, according to the switch's value.
    func changeRangingState() {
        rangingActive = rangingSwitch.isOn
        updateRangingState()
    }
    
    /// Starts/stops the monitoring operation, depending on the state of monitoringActive.
    func updateMonitoringState() {
        self.createLocationManager()
        monitoringActive ? monitoringActivityIndicator.startAnimating() : monitoringActivityIndicator.stopAnimating()
        monitoringActive ? monitoringOperation.startMonitoringForBeacons() : monitoringOperation.stopMonitoringForBeacons()
    }
    
    /// Starts/stops the advertising operation, depending on the state of advertisingActive.
    func updateAdvertisingState() {
        advertisingActive ? advertisingActivityIndicator.startAnimating() : advertisingActivityIndicator.stopAnimating()
        advertisingActive ? advertisingOperation.startAdvertisingBeacon() : advertisingOperation.stopAdvertisingBeacon()
    }
    
    /// Starts/stops the ranging operation, depending on the state of rangingActive.
    func updateRangingState() {
        
        self.createLocationManager()
        rangingActive ? rangingOperation.startRangingForBeacons() : rangingOperation.stopRangingForBeacons()
    }
}

// MARK: - Monitoring delegate methods and helpers
extension ViewController: NATMonitoringOperationDelegate
{
    /**
     Triggered by the monitoring operation when it has started successfully and turns the monitoring switch and
     activity indicator on.
     */
    func monitoringOperationDidStartSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.monitoringActive = true
            self.monitoringActivityIndicator.startAnimating()
            self.sendMessageFor(operation: NATOperationType.monitoring, withState: true)
        }
    }
    
    /// Triggered by the monitoring operation when it has stopped successfully and turns the activity indicator off.
    func monitoringOperationDidStopSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.monitoringActivityIndicator.stopAnimating()
            self.sendMessageFor(operation: NATOperationType.monitoring, withState: false)
        }
    }
    
    /// Triggered by the monitoring operation whe it has failed to start and turns the monitoring switch off.
    func monitoringOperationDidFailToStart() {
        DispatchQueue.main.async { () -> Void in
            self.monitoringActive = false
            self.sendMessageFor(operation: NATOperationType.monitoring, withState: false)
        }
    }
    
    /**
     Triggered by the monitoring operation when it has failed to start due to the last authorization denial.
     It turns the monitoring switch off and presents a UIAlertView to prompt the user to change their location
     access settings.
     */
    func monitoringOperationDidFailToStartDueToAuthorization() {
        let title = "Missing Location Access"
        let message = "Location Access (Always) is required. Click Settings to update the location access settings."
        let cancelButtonTitle = "Cancel"
        let settingsButtonTitle = "Settings"
        
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: nil)
        let settingsAction = UIAlertAction.init(title: settingsButtonTitle, style: UIAlertActionStyle.default) {
            (action: UIAlertAction) -> Void in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(cancelAction);
        alertController.addAction(settingsAction);
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.async { () -> Void in
            self.monitoringActive = false
            self.sendMessageFor(operation: NATOperationType.monitoring, withState: false)
        }
    }
    
    /**
     Triggered by the monitoring operation when it has detected entering the provided region. It emits
     a local notification.
     :param: region The provided region that the monitoring operation detected.
     */
    func monitoringOperationDidDetectEnteringRegion(_ region: CLBeaconRegion) {
        queueNotificationRequestForBeaconRegion(region)
    }
    
    /**
     Queues a UNNotificationRequest with information about the given region.
     Note that major and minor integers are not available at the monitoring stage.
     :param: region The given CLBeaconRegion instance.
     */
    func queueNotificationRequestForBeaconRegion(_ region: CLBeaconRegion) {
        let mutableNotificationContent = UNMutableNotificationContent()
        mutableNotificationContent.title = "Beacon Region Entered"
        mutableNotificationContent.body = "Entered beacon region for UUID: " + region.proximityUUID.uuidString
        mutableNotificationContent.sound = UNNotificationSound.default()
        
        let notificationRequest = UNNotificationRequest(identifier: "RegionEntered", content: mutableNotificationContent, trigger: nil)
        
        UNUserNotificationCenter.current().add(notificationRequest)
    }
}

// MARK: - Advertising delegate methods
extension ViewController: NATAdvertisingOperationDelegate
{
    /**
     Triggered by the advertising operation when it has started successfully and turns the advertising switch and the
     activity indicator on.
     */
    func advertisingOperationDidStartSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.advertisingActive = true
            self.advertisingActivityIndicator.startAnimating()
            self.sendMessageFor(operation: NATOperationType.advertising, withState: true)
        }
    }
    
    /// Triggered by the advertising operation when it has stopped successfully and turns the activity indicator off.
    func advertisingOperationDidStopSuccessfully() {
        DispatchQueue.main.async { () -> Void in
            self.advertisingActivityIndicator.stopAnimating()
            self.sendMessageFor(operation: NATOperationType.advertising, withState: false)
        }
    }
    
    /// Triggered by the advertising operation when ithas failed to start and turns the advertising switch off.
    func advertisingOperationDidFailToStart() {
        let title = "Bluetooth is off"
        let message = "It seems that Bluetooth is off. For advertising to work, please turn Bluetooth on."
        let cancelButtonTitle = "OK"
        
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: nil)
        alertController.addAction(cancelAction);
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.async { () -> Void in
            self.advertisingActive = false
            self.sendMessageFor(operation: NATOperationType.advertising, withState: false)
        }
    }
}

//MARK: -CLLocationManagerDelegate methods

extension ViewController: CLLocationManagerDelegate
{
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: %@", region)
        
        self.sendLocalNotificationForBeaconRegion(region: region as! CLBeaconRegion)
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: %@", region);
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        var stateString:String?
        switch (state) {
        case CLRegionState.inside:
            stateString = "inside"
            break;
        case CLRegionState.outside:
            stateString = "outside"
            break;
        case CLRegionState.unknown:
            stateString = "unknown"
            break;
        }
        print("State changed to %@ for region %@.", stateString!, region);
    }

}

// MARK: - Ranging delegate methods
extension ViewController: NATRangingOperationDelegate
{
    /**
     Triggered by the ranging operation when it has started successfully. It turns the ranging switch on
     and resets the detectedBeacons array.
     */
    func rangingOperationDidStartSuccessfully() {
        detectedBeacons = []
        
        DispatchQueue.main.async { () -> Void in
            self.rangingActive = true
            self.sendMessageFor(operation: NATOperationType.ranging, withState: true)
        }
    }
    
    /// Triggered by the ranging operation when it has failed to start and turns the ranging switch off.
    func rangingOperationDidFailToStart() {
        DispatchQueue.main.async { () -> Void in
            self.rangingActive = false
            self.sendMessageFor(operation: NATOperationType.ranging, withState: false)
        }
    }
    
    /**
     Triggered by the ranging operation when it has failed to start due to the last authorization denial.
     It turns the ranging switch off and presents a UIAlertView to prompt the user to change their location
     access settings.
     */
    func rangingOperationDidFailToStartDueToAuthorization() {
        let title = "Missing Location Access"
        let message = "Location Access (When In Use) is required. Click Settings to update the location access settings."
        let cancelButtonTitle = "Cancel"
        let settingsButtonTitle = "Settings"
        
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction.init(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: nil)
        let settingsAction = UIAlertAction.init(title: settingsButtonTitle, style: UIAlertActionStyle.default) {
            (action: UIAlertAction) -> Void in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        }
        alertController.addAction(cancelAction);
        alertController.addAction(settingsAction);
        self.present(alertController, animated: true, completion: nil)
        
        DispatchQueue.main.async { () -> Void in
            self.rangingActive = false
            self.sendMessageFor(operation: NATOperationType.ranging, withState: false)
        }
    }
    
    /**
     Triggered by the ranging operation when it has stopped successfully. It updates the beacon table view to reflect
     that the ranging has stopped.
     */
    func rangingOperationDidStopSuccessfully() {
        detectedBeacons = []
        
        DispatchQueue.main.async { () -> Void in
            self.beaconTableView.beginUpdates()
            if let deletedSections = self.deletedSections() {
                self.beaconTableView.deleteSections(deletedSections, with: UITableViewRowAnimation.fade)
            }
            self.beaconTableView.endUpdates()
            
            self.sendMessageFor(operation: NATOperationType.ranging, withState: false)
        }
    }
    
    /**
     Triggered by the ranging operation when it has detected beacons belonging to a specific given beacon region.
     It updates the table view to show the newly-found beacons.
     :param: beacons An array of provided beacons that the ranging operation detected.
     :param: region A provided region whose beacons the operation is trying to range.
     */
    func rangingOperationDidRangeBeacons(_ beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        DispatchQueue.main.async { () -> Void in
            let filteredBeacons = self.filteredBeacons(beacons as! [CLBeacon])
            
            if filteredBeacons.isEmpty {
                print("No beacons found nearby.")
            } else {
                let beaconsString: String
                
                if filteredBeacons.count > 1 {
                    beaconsString = "beacons"
                } else {
                    beaconsString = "beacon"
                }
                print("Found \(filteredBeacons.count) \(beaconsString).")
            }
            
            let insertedRows = self.indexPathsOfInsertedBeacons(filteredBeacons)
            let deletedRows = self.indexPathsOfRemovedBeacons(filteredBeacons)
            var reloadedRows: [IndexPath]?
            if deletedRows == nil && insertedRows == nil {
                reloadedRows = self.indexPathsForBeacons(filteredBeacons)
            }
            
            self.detectedBeacons = filteredBeacons
            
            self.beaconTableView.beginUpdates()
            if self.insertedSections() != nil {
                self.beaconTableView.insertSections(self.insertedSections()!, with: UITableViewRowAnimation.fade)
            }
            if self.deletedSections() != nil {
                self.beaconTableView.deleteSections(self.deletedSections()!, with: UITableViewRowAnimation.fade)
            }
            if insertedRows != nil {
                self.beaconTableView.insertRows(at: insertedRows!, with: UITableViewRowAnimation.fade)
            }
            if deletedRows != nil {
                self.beaconTableView.deleteRows(at: deletedRows!, with: UITableViewRowAnimation.fade)
            }
            if reloadedRows != nil {
                self.beaconTableView.reloadRows(at: reloadedRows!, with: UITableViewRowAnimation.fade)
            }
            self.beaconTableView.endUpdates()
            
            if (filteredBeacons.count == 0) {
                print("No beacons found nearby.")
            } else {
                print("Found %lu %@.", filteredBeacons.count, filteredBeacons.count > 1 ? "beacons" : "beacon")
                
                self.count += 1
                if (self.count < 10) {return}
                self.count = 0
                if (!self.isCalling)
                {
                    let state = UIApplication.shared.applicationState;
                    if (state == UIApplicationState.active) {
                        self.makeCall()
                    }
                    else
                    {
                        self.sendLocalNotificationForBeaconRegion(region: region)
                    }
                }
            }
        }
    }
}

// MARK: - WCSessionDelegate methods
extension ViewController: WCSessionDelegate
{
    public func session(_ session: WCSession,
                        activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        if error != nil {
            print("Session failed to activate with error: \(error.debugDescription)")
        }
    }
    
    /// Triggered when a message from the watch has been received.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        performActionFor(message: message as! [String: Bool])
    }
    
    public func sessionDidDeactivate(_ session: WCSession) { }
    
    public func sessionDidBecomeInactive(_ session: WCSession) { }
}

// MARK: - Watch Messaging Methods
extension ViewController
{
    /**
     Triggers any of the three operations in the app. It effectively reflects the actions taken on the watch
     by updating the action UI and triggering the operations, based on the updated UI.
     :param: message The message that caused this method to be called.
     */
    func performActionFor(message: [String: Bool]) {
        if let monitoringState = message[NATOperationType.monitoring.rawValue] {
            DispatchQueue.main.async { () -> Void in
                self.monitoringActive = monitoringState
                self.updateMonitoringState()
            }
        } else if let advertisingState = message[NATOperationType.advertising.rawValue] {
            DispatchQueue.main.async { () -> Void in
                self.advertisingActive = advertisingState
                self.updateAdvertisingState()
            }
        } else if let rangingState = message[NATOperationType.ranging.rawValue] {
            DispatchQueue.main.async{ () -> Void in
                self.rangingActive = rangingState
                self.updateRangingState()
            }
        }
    }
    
    /**
     Prepares and sends a message to trigger a change to a given state of the given operation
     on the phone.
     :param: operation The operation for which the state should be changed.
     :param: state The new state for the given operation.
     */
    func sendMessageFor(operation: NATOperationType, withState state: Bool) {
        let payload = [operation.rawValue: state]
        mainSession!.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - CLBeacon extension
extension CLBeacon
{
    /// Returns a specially-formatted description of the beacon's characteristics.
    func fullDetails() -> String {
        let proximityText: String
        
        switch proximity {
        case .near:
            proximityText = "Near"
        case .immediate:
            proximityText = "Immediate"
        case .far:
            proximityText = "Far"
        case .unknown:
            proximityText = "Unknown"
        }
        
        return "\(major), \(minor) •  \(proximityText) • \(accuracy) • \(rssi)"
    }
}


