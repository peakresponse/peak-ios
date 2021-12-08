//
//  AppRealm.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import RealmSwift
import Starscream

class RequestOperation: Operation {
    override var isAsynchronous: Bool {
        return true
    }

    private var _isExecuting = false
    override var isExecuting: Bool {
        return _isExecuting
    }

    private var _isFinished = false
    override var isFinished: Bool {
        return _isFinished
    }

    override var isReady: Bool {
        return true
    }

    var retryTime: TimeInterval = 0
    var data: [String: Any]?

    var request: ((@escaping (Error?) -> Void) -> URLSessionTask)!

    override func start() {
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")

        performRequest()
    }

    private func performRequest() {
        let task = request(completionHandler)
        task.resume()
    }

    private func completionHandler(error: Error?) {
        if error != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + retryTime) { [weak self] in
                self?.performRequest()
            }
            if retryTime == 0 {
                retryTime = 0.5
            } else if retryTime < 4 {
                retryTime *= 2
            }
        } else {
            willChangeValue(forKey: "isFinished")
            _isFinished = true
            didChangeValue(forKey: "isFinished")
        }
    }
}

// swiftlint:disable file_length force_try type_body_length
class AppRealm {
    private static var main: Realm!
    private static var _queue: OperationQueue!
    private static var queue: OperationQueue {
        if _queue == nil {
            _queue = OperationQueue()
            _queue.maxConcurrentOperationCount = 1
        }
        return _queue
    }

    private static var agencySocket: WebSocket?
    private static var sceneSocket: WebSocket?

    private static var locationHelper: LocationHelper?

    public static func open() -> Realm {
        if Thread.current.isMainThread && AppRealm.main != nil {
            AppRealm.main.refresh()
            return AppRealm.main
        }
        let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                             appropriateFor: nil, create: false)
        let url = documentDirectory?.appendingPathComponent( "app.realm")
        let config = Realm.Configuration(fileURL: url, deleteRealmIfMigrationNeeded: true)
        let realm = try! Realm(configuration: config)
        if Thread.current.isMainThread {
            AppRealm.main = realm
        }
        return realm
    }

    public static func deleteAll() {
        let realm = AppRealm.open()
        try! realm.write {
            realm.deleteAll()
        }
    }

    // MARK: - Agencies

    public static func connect() {
        agencySocket?.disconnect()
        agencySocket = ApiClient.shared.connect(completionHandler: { (socket, data, error) in
            guard socket == agencySocket else { return }
            if error != nil {
                // close current connection
                agencySocket?.forceDisconnect()
                agencySocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    connect()
                }
            } else if let data = data {
                if let records = data["scenes"] as? [[String: Any]] {
                    let scenes = records.map({ Scene.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(scenes, update: .modified)
                    }
                }
            } else {
                AppSettings.lastPingDate = Date()
            }
        })
        agencySocket?.connect()
    }

    public static func disconnect() {
        agencySocket?.disconnect()
        agencySocket = nil
    }

    public static func getAgencies(search: String? = nil, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getAgencies(search: search, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let agencies = records.map({ Agency.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(agencies, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    // MARK: - Assignments

    public static func createAssignment(number: String?, vehicleId: String?, completionHandler: @escaping (Assignment?, Error?) -> Void) {
        var data: [String: Any] = [:]
        if let number = number {
            data["number"] = number
        } else if let vehicleId = vehicleId {
            data["vehicleId"] = vehicleId
        } else {
            data["vehicleId"] = NSNull()
        }
        let task = ApiClient.shared.createAssignment(data: data) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data {
                let assignment = Assignment.instantiate(from: data)
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(assignment, update: .modified)
                }
                completionHandler(assignment as? Assignment, nil)
            }
        }
        task.resume()
    }

    // MARK: - Facilities

    public static func getFacilities(lat: String, lng: String, search: String? = nil, type: String? = nil,
                                     completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getFacilities(lat: lat, lng: lng, search: search, type: type, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                var origin: CLLocation?
                if let lat = Double(lat), let lng = Double(lng) {
                    origin = CLLocation(latitude: lat, longitude: lng)
                }
                let facilities = records.map({ (record) -> Base in
                    let facility = Facility.instantiate(from: record)
                    if let facility = facility as? Facility, let latlng = facility.latlng, let origin = origin {
                        facility.distance = latlng.distance(from: origin)
                    }
                    return facility
                })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(facilities, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    // MARK: - Incidents

    public static func getIncidents(vehicleId: String? = nil, search: String? = nil,
                                    completionHandler: @escaping (String?, Error?) -> Void) {
        let task = ApiClient.shared.getIncidents(vehicleId: vehicleId, search: search) { (_, response, records, error) in
            AppRealm.handleIncidentsResponse(response: response, records: records, error: error,
                                             completionHandler: completionHandler)
        }
        task.resume()
    }

    public static func getNextIncidents(url: String, completionHandler: @escaping (String?, Error?) -> Void) {
        let task = ApiClient.shared.GET(path: url, params: nil) { (_, response, records: [[String: Any]]?, error) in
            AppRealm.handleIncidentsResponse(response: response, records: records, error: error,
                                             completionHandler: completionHandler)
        }
        task.resume()
    }

    private static func handleIncidentsResponse(response: URLResponse?, records: [[String: Any]]?, error: Error?,
                                                completionHandler: @escaping (String?, Error?) -> Void) {
        if let error = error {
            completionHandler(nil, error)
        } else if let records = records {
            var cities: [Base] = []
            var states: [Base] = []
            var scenes: [[String: Any]] = []
            var dispatches: [[String: Any]] = []
            for record in records {
                if let scene = record["scene"] as? [String: Any] {
                    if let city = scene["city"] as? [String: Any] {
                        cities.append(City.instantiate(from: city))
                    }
                    if let state = scene["state"] as? [String: Any] {
                        states.append(State.instantiate(from: state))
                    }
                    scenes.append(scene)
                }
                if let newDispatches = record["dispatches"] as? [[String: Any]] {
                    dispatches.append(contentsOf: newDispatches)
                }
            }
            let realm = AppRealm.open()
            try! realm.write {
                realm.add(cities, update: .modified)
                realm.add(states, update: .modified)
                realm.add(scenes.map { Scene.instantiate(from: $0) }, update: .modified)
                realm.add(records.map { Incident.instantiate(from: $0) }, update: .modified)
                realm.add(dispatches.map { Dispatch.instantiate(from: $0) }, update: .modified)
            }
            var nextUrl: String?
            if let links = ApiClient.parseLinkHeader(from: response) {
                nextUrl = links["next"]
            }
            completionHandler(nextUrl, nil)
        }
    }

    // MARK: - List

    public static func getLists(completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getLists { (_, _, data, error) in
            if let error = error {
                completionHandler(error)
            } else if let data = data {
                let realm = AppRealm.open()
                try! realm.write {
                    if let lists = data["lists"] as? [[String: Any]] {
                        realm.add(lists.map { CodeList.instantiate(from: $0) }, update: .modified)
                    }
                    if let sections = data["sections"] as? [[String: Any]] {
                        realm.add(sections.map { CodeListSection.instantiate(from: $0) }, update: .modified)
                    }
                    if let items = data["items"] as? [[String: Any]] {
                        realm.add(items.map { CodeListItem.instantiate(from: $0) }, update: .modified)
                    }
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    // MARK: - Patients

    public static func getPatients(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getPatients(sceneId: sceneId, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let patients = records.map({ Patient.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(patients, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    public static func getPatient(idOrPin: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getPatient(idOrPin: idOrPin) { (_, _, record, error) in
            if let record = record {
                if let patient = Patient.instantiate(from: record) as? Patient {
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(patient, update: .modified)
                    }
                }
            }
            completionHandler(error)
        }
        task.resume()
    }

    public static func createOrUpdatePatient(patient: Patient) {
        let realm = AppRealm.open()
        try! realm.write {
            realm.add(patient, update: .modified)
        }
        let op = RequestOperation()
        op.queuePriority = .veryHigh
        let data = patient.asJSON()
        op.request = { (completionHandler) in
            return ApiClient.shared.createOrUpdatePatient(data: data) { (_, _, record, error) in
                if let record = record {
                    if let patient = Patient.instantiate(from: record) as? Patient {
                        let realm = AppRealm.open()
                        try! realm.write {
                            realm.add(patient, update: .modified)
                        }
                    }
                }
                completionHandler(error)
            }
        }
        queue.addOperation(op)
    }

    public static func uploadPatientAsset(patient: Patient, key: String, fileURL: URL) {
        /// ensure a unique upload filename by prepending the user uuid
        let fileName = "\(AppSettings.userId ?? "")/\(fileURL.lastPathComponent)"
        if let realm = patient.realm {
            try! realm.write {
                patient.setValue(fileName, forKey: key)
            }
        } else {
            patient.setValue(fileName, forKey: key)
        }
        /// move to the local app file cache
        let cacheFileURL = AppCache.cache(fileURL: fileURL, filename: fileName)
        let op = RequestOperation()
        op.queuePriority = .veryHigh
        op.request = { (completionHandler) in
            if let data = op.data,
               let directUpload = data["direct_upload"] as? [String: Any],
               let urlString = directUpload["url"] as? String,
               let url = URL(string: urlString),
               let headers = directUpload["headers"] as? [String: Any] {
                return ApiClient.shared.upload(fileURL: cacheFileURL ?? fileURL, toURL: url, headers: headers) { (error) in
                    completionHandler(error)
                }
            } else {
                return ApiClient.shared.upload(fileName: fileName, fileURL: cacheFileURL ?? fileURL) { (_, _, response, error) in
                    if let error = error {
                        completionHandler(error)
                    } else if let response = response {
                        op.data = response
                        op.retryTime = 0
                        completionHandler(ApiClientError.unexpected)
                    }
                }
            }
        }
        queue.addOperation(op)
    }

    // MARK: - Scene

    public static func captureLocation(sceneId: String) {
        DispatchQueue.main.async {
            let locationHelper = LocationHelper()
            locationHelper.didUpdateLocations = { (locations) in
                if let location = locations.last {
                    let lat = String(format: "%.6f", location.coordinate.latitude)
                    let lng = String(format: "%.6f", location.coordinate.longitude)
                    let op = RequestOperation()
                    op.request = { (completionHandler) in
                        if let scene = AppRealm.open().object(ofType: Scene.self, forPrimaryKey: sceneId),
                           let parentSceneId = scene.currentId {
                            return ApiClient.shared.updateScene(data: [
                                "id": UUID().uuidString.lowercased(),
                                "parentId": parentSceneId,
                                "lat": lat,
                                "lng": lng
                            ]) { (_, _, _, error) in
                                completionHandler(error)
                            }
                        }
                        fatalError()
                    }
                    AppRealm.queue.addOperation(op)
                }
                AppRealm.locationHelper = nil
            }
            locationHelper.didFailWithError = { (_) in
                AppRealm.locationHelper = nil
            }
            AppRealm.locationHelper = locationHelper
            locationHelper.requestLocation()
        }
    }

    public static func getScenes(completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getScenes { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let scenes = records.map({ Scene.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scenes, update: .modified)
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    public static func createScene(scene: Scene, completionHandler: @escaping (Scene?, Error?) -> Void) {
        let canonical = Scene(clone: scene)
        canonical.id = canonical.canonicalId!
        canonical.canonicalId = nil
        let realm = AppRealm.open()
        try! realm.write {
            realm.add([scene, canonical], update: .modified)
        }
        let task = ApiClient.shared.createScene(data: scene.asJSON()) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data, let scene = Scene.instantiate(from: data) as? Scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                }
                completionHandler(scene, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    public static func getScene(sceneId: String, completionHandler: @escaping (Scene?, Error?) -> Void) {
        let task = ApiClient.shared.getScene(sceneId: sceneId) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data, let scene = Scene.instantiate(from: data) as? Scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                }
                completionHandler(scene, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    public static func closeScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.closeScene(sceneId: sceneId) { (_, _, data, error) in
            if let error = error {
                completionHandler(error)
            } else if let data = data, let scene = Scene.instantiate(from: data) as? Scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                }
                completionHandler(nil)
            } else {
                completionHandler(ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    public static func joinScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.joinScene(sceneId: sceneId) { (_, _, _, error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func createOrUpdateScenePin(sceneId: String, pin: ScenePin) {
        let realm = AppRealm.open()
        try! realm.write {
            pin.scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
            realm.add(pin, update: .modified)
            if let prevPinId = pin.prevPinId, let prevPin = realm.object(ofType: ScenePin.self, forPrimaryKey: prevPinId) {
                prevPin.deletedAt = Date()
            }
        }
        let op = RequestOperation()
        let data = pin.asJSON()
        op.request = { (completionHandler) in
            return ApiClient.shared.addScenePin(sceneId: sceneId, data: data, completionHandler: completionHandler)
        }
        queue.addOperation(op)
    }

    public static func removeScenePin(_ pin: ScenePin) {
        guard let sceneId = pin.scene?.id else { return }
        let realm = AppRealm.open()
        try! realm.write {
            pin.deletedAt = Date()
        }
        let op = RequestOperation()
        let scenePinId = pin.id
        op.request = { (completionHandler) in
            return ApiClient.shared.removeScenePin(sceneId: sceneId, scenePinId: scenePinId, completionHandler: completionHandler)
        }
        queue.addOperation(op)
    }

    public static func leaveScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.leaveScene(sceneId: sceneId) { (_, _, _, error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func transferScene(sceneId: String, userId: String, agencyId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.transferScene(sceneId: sceneId, userId: userId, agencyId: agencyId) { (error) in
            completionHandler(error)
        }
        task.resume()
    }

    public static func connect(sceneId: String) {
        // cancel any existing task
        sceneSocket?.disconnect()
        // connect to scene socket
        sceneSocket = ApiClient.shared.connect(sceneId: sceneId) { (socket, data, error) in
            guard socket == sceneSocket else { return }
            if error != nil {
                // close current connection
                sceneSocket?.forceDisconnect()
                sceneSocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    connect(sceneId: sceneId)
                }
            } else if let data = data {
                let realm = AppRealm.open()
                if let scene = data["scene"] as? [String: Any] {
                    if let scene = Scene.instantiate(from: scene) as? Scene {
                        try! realm.write {
                            realm.add(scene, update: .modified)
                        }
                    }
                }
                if let patients = data["patients"] as? [[String: Any]] {
                    let patients = patients.map({ Patient.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(patients, update: .modified)
                    }
                }
                if let pins = data["pins"] as? [[String: Any]] {
                    let pins = pins.map({ ScenePin.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(pins, update: .modified)
                    }
                }
                if let responders = data["responders"] as? [[String: Any]] {
                    let responders = responders.map({ Responder.instantiate(from: $0) })
                    let realm = AppRealm.open()
                    try! realm.write {
                        realm.add(responders, update: .modified)
                    }
                }
            } else {
                let now = Date()
                AppSettings.lastPingDate = now
                AppSettings.lastScenePingDate = now
            }
        }
        sceneSocket?.connect()
    }

    public static func disconnectScene() {
        sceneSocket?.disconnect()
        sceneSocket = nil
    }

    public static func updateApproxPatientsCounts(sceneId: String, priority: Priority?, delta: Int) {
        let realm = AppRealm.open()
        try! realm.write {
            if let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId),
               let parentSceneId = scene.currentId {
                if let priority = priority, var approxPriorityPatientsCounts = scene.approxPriorityPatientsCounts {
                    if approxPriorityPatientsCounts.count > priority.rawValue {
                        approxPriorityPatientsCounts[priority.rawValue] += delta
                        scene.approxPriorityPatientsCounts = approxPriorityPatientsCounts
                    }
                } else {
                    scene.approxPatientsCount = (scene.approxPatientsCount ?? 0) + delta
                }
                struct Debounce {
                    static var timer: Timer?
                }
                if let timer = Debounce.timer {
                    timer.invalidate()
                }
                var data: [String: Any] = [
                    "id": UUID().uuidString.lowercased(),
                    "parentId": parentSceneId
                ]
                if let approxPatientsCount = scene.approxPatientsCount {
                    data["approxPatientsCount"] = approxPatientsCount
                }
                if let approxPriorityPatientsCounts = scene.approxPriorityPatientsCounts {
                    data["approxPriorityPatientsCounts"] = approxPriorityPatientsCounts
                }
                Debounce.timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (_) in
                    let op = RequestOperation()
                    op.request = { (completionHandler) in
                        return ApiClient.shared.updateScene(data: data) { (_, _, _, error) in
                            completionHandler(error)
                        }
                    }
                    AppRealm.queue.addOperation(op)
                })
            }
        }
    }

    // MARK: - Responders

    public static func getResponders(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = ApiClient.shared.getResponders(sceneId: sceneId) { (_, _, responders, error) in
            if let error = error {
                completionHandler(error)
            } else if let responders = responders {
                let responders = responders.map({ Responder.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(responders, update: .modified)
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    public static func assignResponder(responderId: String, role: ResponderRole?) {
        let realm = open()
        try! realm.write {
            let responder = realm.object(ofType: Responder.self, forPrimaryKey: responderId)
            responder?.role = role?.rawValue
        }
        let op = RequestOperation()
        op.request = { (completionHandler) in
            return ApiClient.shared.assignResponder(responderId: responderId, role: role?.rawValue, completionHandler: completionHandler)
        }
        queue.addOperation(op)
    }

    // MARK: - Users

    public static func me(completionHandler: @escaping (User?, Agency?, Assignment?, Scene?, Error?) -> Void) {
        let task = ApiClient.shared.me { (_, _, data, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, nil, error)
                }
            } else if let data = data {
                var user: User?
                var agency: Agency?
                var assignment: Assignment?
                var vehicle: Vehicle?
                var activeScenes: [Base]?
                if let data = data["user"] as? [String: Any] {
                    user = User.instantiate(from: data) as? User
                    if let data = data["activeScenes"] as? [[String: Any]] {
                        activeScenes = data.map({ Scene.instantiate(from: $0) })
                    }
                    if let data = data["currentAssignment"] as? [String: Any] {
                        if let data = data["vehicle"] as? [String: Any] {
                            vehicle = Vehicle.instantiate(from: data) as? Vehicle
                        }
                        assignment = Assignment.instantiate(from: data) as? Assignment
                    }
                }
                if let data = data["agency"] as? [String: Any] {
                    agency = Agency.instantiate(from: data) as? Agency
                }
                let realm = AppRealm.open()
                try! realm.write {
                    if let user = user {
                        realm.add(user, update: .modified)
                    }
                    if let agency = agency {
                        realm.add(agency, update: .modified)
                    }
                    if let assignment = assignment {
                        realm.add(assignment, update: .modified)
                    }
                    if let vehicle = vehicle {
                        realm.add(vehicle, update: .modified)
                    }
                    if let activeScenes = activeScenes {
                        realm.add(activeScenes, update: .modified)
                    }
                }
                var scene: Scene?
                if let activeScenes = activeScenes, activeScenes.count > 0 {
                    scene = activeScenes[0] as? Scene
                }
                completionHandler(user, agency, assignment, scene, nil)
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, nil, ApiClientError.unexpected)
                }
            }
        }
        task.resume()
    }

    // MARK: - Vehicles

    public static func getVehicles(completionHandler: @escaping (Error?) -> Void) {
        var vehiclesCompletionHandler: ((URLRequest, URLResponse?, [[String: Any]]?, Error?) -> Void)!
        vehiclesCompletionHandler = { (_, response, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let vehicles = records.map({ Vehicle.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(vehicles, update: .modified)
                }
                if let links = ApiClient.parseLinkHeader(from: response), let next = links["next"] {
                    let task = ApiClient.shared.GET(path: next, params: nil, completionHandler: vehiclesCompletionHandler)
                    task.resume()
                } else {
                    completionHandler(nil)
                }
            }
        }
        let task = ApiClient.shared.getVehicles(completionHandler: vehiclesCompletionHandler)
        task.resume()
    }
}
