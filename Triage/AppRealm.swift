//
//  AppRealm.swift
//  Triage
//
//  Created by Francis Li on 11/1/19.
//  Copyright © 2019 Francis Li. All rights reserved.
//

import CoreLocation
import PRKit
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
    private static var mainUrl: URL?
    private static var main: Realm!
    private static var _queue: OperationQueue!
    private static var queue: OperationQueue {
        if _queue == nil {
            _queue = OperationQueue()
            _queue.maxConcurrentOperationCount = 1
        }
        return _queue
    }

    private static var incidentsSocket: WebSocket?
    private static var sceneSocket: WebSocket?

    private static var locationHelper: LocationHelper?

    public static func configure(url: URL?) {
        mainUrl = url
        main = nil
    }

    public static func open() -> Realm {
        if Thread.current.isMainThread && AppRealm.main != nil {
            return AppRealm.main
        }
        var url: URL! = mainUrl
        if url == nil {
            let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                                 appropriateFor: nil, create: false)
            url = documentDirectory?.appendingPathComponent( "app.realm")
        }
        let config = Realm.Configuration(fileURL: url, deleteRealmIfMigrationNeeded: true, objectTypes: [
            Agency.self, Assignment.self, City.self, CodeList.self, CodeListSection.self, CodeListItem.self, Dispatch.self,
            Disposition.self, Facility.self, File.self, Form.self, History.self, Incident.self, Medication.self, Narrative.self, Patient.self,
            Procedure.self, Region.self, RegionAgency.self, RegionFacility.self, Report.self, Responder.self, Response.self,
            Scene.self, ScenePin.self, Signature.self, Situation.self, State.self, Time.self, User.self, Vehicle.self, Vital.self
        ])
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

    private static func handlePayload(data: [String: Any]?) {
        let realm = AppRealm.open()
        try! realm.write {
            for model in [
                // models without dependencies in alpha order
                Agency.self,
                Assignment.self,
                City.self,
                Facility.self,
                File.self,
                Form.self,
                History.self,
                Medication.self,
                Narrative.self,
                Patient.self,
                Procedure.self,
                Region.self,
                Response.self,
                Situation.self,
                State.self,
                Time.self,
                User.self,
                Vehicle.self,
                Vital.self,
                // models with dependencies on above in dependency order
                Disposition.self,
                RegionAgency.self,
                RegionFacility.self,
                Responder.self,
                Signature.self,
                Scene.self,
                Incident.self,
                Dispatch.self,
                // report has dependencies on all of above
                Report.self
            ] {
                var records = data?[String(describing: model)] as? [[String: Any]]
                if records == nil, let record = data?[String(describing: model)] as? [String: Any] {
                    records = [record]
                }
                if let objs = records?.map({ model.instantiate(from: $0, with: realm) }) {
                    // special case handling for Scene, which we reference as both canonical top-level and current dependent records
                    if let objs = objs as? [Scene] {
                        for obj in objs {
                            if let currentId = obj.currentId {
                                if realm.objects(Scene.self).filter("parentId=%@ OR secondParentId=%@", currentId, currentId).count == 0 {
                                    realm.add(obj, update: .modified)
                                    if let current = Scene(current: obj) {
                                        realm.add(current, update: .modified)
                                    }
                                }
                            } else {
                                realm.add(obj, update: .modified)
                            }
                        }
                    } else {
                        realm.add(objs, update: .modified)
                    }
                }
            }
        }
    }

    // MARK: - Agencies

    public static func getAgencies(search: String? = nil, completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getAgencies(search: search, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let realm = AppRealm.open()
                try! realm.write {
                    let agencies = records.map({ Agency.instantiate(from: $0, with: realm) })
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
        let task = PRApiClient.shared.createAssignment(data: data) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data {
                AppRealm.handlePayload(data: data)
                var assignment: Assignment?
                if let data = data["Assignment"] as? [String: Any], let id = data["id"] as? String {
                    assignment = AppRealm.open().object(ofType: Assignment.self, forPrimaryKey: id)
                }
                completionHandler(assignment, nil)
            }
        }
        task.resume()
    }

    // MARK: - Cities

    public static func getCities(search: String, location: CLLocationCoordinate2D? = nil, completionHandler: @escaping (Error?) -> Void) {
        var lat: String?
        var lng: String?
        if let location = location {
            lat = String(location.latitude)
            lng = String(location.longitude)
        }
        let task = PRApiClient.shared.getCities(search: search, lat: lat, lng: lng, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                var loc: CLLocation?
                if let location = location {
                    loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
                }
                let realm = AppRealm.open()
                try! realm.write {
                    let cities: [Base] = records.map({
                        let obj = City.instantiate(from: $0, with: realm)
                        if let loc = loc, let city = obj as? City, let primaryLocation = city.primaryLocation {
                            city.distance = loc.distance(from: primaryLocation)
                        }
                        return obj
                    })
                    realm.add(cities, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    // MARK: - Facilities

    public static func getFacilities(lat: String, lng: String, search: String? = nil, type: String? = nil,
                                     completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getFacilities(lat: lat, lng: lng, search: search, type: type, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                var origin: CLLocation?
                if let lat = Double(lat), let lng = Double(lng) {
                    origin = CLLocation(latitude: lat, longitude: lng)
                }
                let realm = AppRealm.open()
                try! realm.write {
                    let facilities = records.map({ (record) -> Base in
                        let facility = Facility.instantiate(from: record, with: realm)
                        if let facility = facility as? Facility, let latlng = facility.latlng, let origin = origin {
                            facility.distance = latlng.distance(from: origin)
                        }
                        return facility
                    })
                    realm.add(facilities, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    public static func fetchFacilities(payload: [String: [String]], completionHandler: ((Error?) -> Void)? = nil) {
        let task = PRApiClient.shared.fetchFacilities(payload: payload) { (_, _, records, error) in
            if let error = error {
                completionHandler?(error)
            } else if let records = records {
                let realm = AppRealm.open()
                try! realm.write {
                    let facilities = records.map { Facility.instantiate(from: $0, with: realm)}
                    realm.add(facilities, update: .modified)
                }
                completionHandler?(nil)
            }
        }
        task.resume()
    }

    // MARK: - Files

    public static func uploadFile(fileURL: URL) {
        let fileName = fileURL.lastPathComponent
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
                return PRApiClient.shared.upload(fileURL: cacheFileURL ?? fileURL, toURL: url, headers: headers) { (error) in
                    completionHandler(error)
                }
            } else {
                return PRApiClient.shared.upload(fileName: fileName, fileURL: cacheFileURL ?? fileURL) { (_, _, response, error) in
                    if let error = error {
                        completionHandler(error)
                    } else if let response = response {
                        op.data = response
                        op.retryTime = 0
                        /// set an arbitrary error so that the operation will be repeated, and the above conditional block will be executed to complete the upload
                        completionHandler(ApiClientError.unexpected)
                    }
                }
            }
        }
        queue.addOperation(op)
    }

    // MARK: - Forms

    public static func getForms(completionHandler: ((Error?) -> Void)? = nil) {
        let task = PRApiClient.shared.getForms { (_, _, data, error) in
            if let error = error {
                completionHandler?(error)
            } else if let data = data {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(data.map { Form.instantiate(from: $0, with: realm) }, update: .modified)
                }
                completionHandler?(nil)
            }
        }
        task.resume()
    }

    // MARK: - Geocode

    public static func geocode(location: CLLocationCoordinate2D, completionHandler: @escaping (([String: Any]?, Error?) -> Void)) {
        let task = PRApiClient.shared.geocode(lat: String(location.latitude), lng: String(location.longitude)) { (_, _, data, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let data = data {
                let realm = AppRealm.open()
                try! realm.write {
                    if let data = data["state"] as? [String: Any] {
                        realm.add(State.instantiate(from: data, with: realm), update: .modified)
                    }
                    if let data = data["city"] as? [String: Any], let city = City.instantiate(from: data, with: realm) as? City {
                        if let primaryLocation = city.primaryLocation {
                            city.distance = CLLocation(latitude: location.latitude, longitude: location.longitude).distance(from: primaryLocation)
                        }
                        realm.add(city, update: .modified)
                    }
                }
                completionHandler(data, nil)
            } else {
                completionHandler(nil, ApiClientError.unexpected)
            }
        }
        task.resume()
    }

    // MARK: - Incidents

    public static func connectIncidents() {
        incidentsSocket?.disconnect()
        guard let assignmentId = AppSettings.assignmentId else { return }
        incidentsSocket = PRApiClient.shared.incidents(assignmentId: assignmentId, completionHandler: { (socket, data, error) in
            guard socket == incidentsSocket else { return }
            if error != nil {
                // close current connection
                incidentsSocket?.forceDisconnect()
                incidentsSocket = nil
                // retry after 5 secs
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    connectIncidents()
                }
            } else if let data = data {
                AppRealm.handlePayload(data: data)
            } else {
                AppSettings.lastPingDate = Date()
            }
        })
        incidentsSocket?.connect()
    }

    public static func disconnectIncidents() {
        incidentsSocket?.disconnect()
        incidentsSocket = nil
    }

    public static func getIncidents(vehicleId: String? = nil, search: String? = nil,
                                    completionHandler: @escaping (String?, Error?) -> Void) {
        let task = PRApiClient.shared.getIncidents(vehicleId: vehicleId, search: search) { (_, response, records, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let records = records {
                AppRealm.handlePayload(data: records)
                var nextUrl: String?
                if let links = PRApiClient.parseLinkHeader(from: response) {
                    nextUrl = links["next"]
                }
                completionHandler(nextUrl, nil)
            }
        }
        task.resume()
    }

    public static func getNextIncidents(url: String, completionHandler: @escaping (String?, Error?) -> Void) {
        let task = PRApiClient.shared.GET(path: url, params: nil) { (_, response, records: [String: Any]?, error) in
            if let error = error {
                completionHandler(nil, error)
            } else if let records = records {
                AppRealm.handlePayload(data: records)
                var nextUrl: String?
                if let links = PRApiClient.parseLinkHeader(from: response) {
                    nextUrl = links["next"]
                }
                completionHandler(nextUrl, nil)
            }
        }
        task.resume()
    }

    // MARK: - List

    public static func getLists(completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getLists { (_, _, data, error) in
            if let error = error {
                completionHandler(error)
            } else if let data = data {
                let realm = AppRealm.open()
                try! realm.write {
                    if let lists = data["lists"] as? [[String: Any]] {
                        realm.add(lists.map { CodeList.instantiate(from: $0, with: realm) }, update: .modified)
                    }
                    if let sections = data["sections"] as? [[String: Any]] {
                        realm.add(sections.map { CodeListSection.instantiate(from: $0, with: realm) }, update: .modified)
                    }
                    if let items = data["items"] as? [[String: Any]] {
                        realm.add(items.map { CodeListItem.instantiate(from: $0, with: realm) }, update: .modified)
                    }
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    // MARK: - Patients

    public static func getPatients(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getPatients(sceneId: sceneId, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let realm = AppRealm.open()
                try! realm.write {
                    let patients = records.map({ Patient.instantiate(from: $0, with: realm) })
                    realm.add(patients, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    public static func getPatient(idOrPin: String, completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getPatient(idOrPin: idOrPin) { (_, _, record, error) in
            if let record = record {
                let realm = AppRealm.open()
                try! realm.write {
                    if let patient = Patient.instantiate(from: record, with: realm) as? Patient {
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
            return PRApiClient.shared.createOrUpdatePatient(data: data) { (_, _, record, error) in
                if let record = record {
                    let realm = AppRealm.open()
                    try! realm.write {
                        if let patient = Patient.instantiate(from: record, with: realm) as? Patient {
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
                return PRApiClient.shared.upload(fileURL: cacheFileURL ?? fileURL, toURL: url, headers: headers) { (error) in
                    completionHandler(error)
                }
            } else {
                return PRApiClient.shared.upload(fileName: fileName, fileURL: cacheFileURL ?? fileURL) { (_, _, response, error) in
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

    // MARK: - Report

    public static func getReports(incident: Incident, completionHandler: @escaping (Results<Report>?, Error?) -> Void) {
        let task = PRApiClient.shared.getReports(incidentId: incident.id) { (_, _, data, error) in
            AppRealm.handlePayload(data: data)
            var reportIds: [String] = []
            if let records = data?["Report"] as? [[String: Any]] {
                reportIds.append(contentsOf: records.map { $0["id"] as! String })
            }
            DispatchQueue.main.async {
                if let error = error {
                    completionHandler(nil, error)
                } else {
                    let realm = AppRealm.open()
                    let results = realm.objects(Report.self).filter("id IN %@", reportIds)
                    completionHandler(results, nil)
                }
            }
        }
        task.resume()
    }

    public static func saveReport(report: Report) {
        let realm = AppRealm.open()
        var parent: Report?
        if let parentId = report.parentId {
            parent = realm.object(ofType: Report.self, forPrimaryKey: parentId)
            if parent == nil {
                let results = realm.objects(Report.self).filter("currentId=%@", parentId)
                if results.count == 1 {
                    parent = results[0]
                }
            }
            if parent == nil {
                fatalError()
            }
        }
        report.updatedAt = Date()
        var data = report.canonicalize(from: parent)
        try! realm.write {
            // if new Incident, create Dispatch for current vehicle, if any
            if let incident = report.incident, incident.realm == nil {
                if let vehicleId = AppSettings.vehicleId {
                    let newDispatch = Dispatch.newRecord()
                    newDispatch.incident = incident
                    newDispatch.vehicleId = vehicleId
                    newDispatch.dispatchedAt = Date()
                    realm.add(newDispatch, update: .modified)
                    data["Dispatch"] = newDispatch.asJSON()
                }
            }
            realm.add(report, update: .modified)
            // create/update the canonical record for the Report and Scene
            if let canonical = Report(canonicalize: report) {
                realm.add(canonical, update: .modified)
            }
            if let scene = report.scene, let canonical = Scene(canonicalize: scene) {
                realm.add(canonical, update: .modified)
            }
            if report.parentId == nil || report.canonicalId != parent?.canonicalId, let incident = report.incident {
                // locally increment incidents count
                incident.reportsCount = (incident.reportsCount ?? 0) + 1
            }
        }
        let op = RequestOperation()
        op.queuePriority = .veryHigh
        op.request = { (completionHandler) in
            return PRApiClient.shared.createOrUpdateReport(data: data) { (_, _, data, error) in
                if error == nil, let data = data {
                    AppRealm.handlePayload(data: data)
                }
                completionHandler(error)
            }
        }
        queue.addOperation(op)
    }

    // MARK: - Scene

    public static func startScene(report: Report, completionHandler: @escaping (String?, Error?) -> Void) {
        guard let sceneId = report.scene?.canonicalId ?? report.scene?.id else { return }
        if report.incident?.realm == nil {
            let data = report.canonicalize(from: nil)
            // save only the incident and scene, canonicalize scene
            if let incident = report.incident, let scene = report.scene {
                let realm = AppRealm.open()
                try! realm.write {
                    realm.add(scene, update: .modified)
                    if let canonical = Scene(canonicalize: scene) {
                        realm.add(canonical, update: .modified)
                    }
                    realm.add(incident, update: .modified)
                }
            }
            let task = PRApiClient.shared.createOrUpdateReport(data: [
                "Scene": data["Scene"] as Any,
                "Incident": data["Incident"] as Any
            ]) { (_, _, data, error) in
                if let error = error {
                    completionHandler(sceneId, error)
                } else {
                    if let data = data {
                        AppRealm.handlePayload(data: data)
                    }
                    AppRealm.startScene(sceneId: sceneId, completionHandler: completionHandler)
                }
            }
            task.resume()
        } else {
            AppRealm.startScene(sceneId: sceneId, completionHandler: completionHandler)
        }
    }

    private static func startScene(sceneId: String, completionHandler: @escaping (String?, Error?) -> Void) {
        let realm = AppRealm.open()
        if let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId),
           let userId = AppSettings.userId,
           let user = realm.object(ofType: User.self, forPrimaryKey: userId),
           let agencyId = AppSettings.agencyId,
           let agency = realm.object(ofType: Agency.self, forPrimaryKey: agencyId) {
            let responder = Responder()
            responder.user = user
            responder.agency = agency
            if let vehicleId = AppSettings.vehicleId {
                responder.vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId)
            }
            responder.arrivedAt = Date()
            let newScene = Scene(clone: scene)
            newScene.isMCI = true
            newScene.mgsResponderId = responder.id
            if let canonicalId = newScene.canonicalId, let canonical = Scene(canonicalize: newScene), let changes = newScene.changes(from: scene) {
                responder.scene = canonical
                let data = [
                    "Responder": responder.asJSON(),
                    "Scene": changes
                ]
                try! realm.write {
                    realm.add(canonical, update: .modified)
                    realm.add(newScene, update: .modified)
                    realm.add(responder, update: .modified)
                }
                let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                    completionHandler(canonicalId, error)
                    if error != nil {
                        let op = RequestOperation()
                        op.queuePriority = .veryHigh
                        op.request = { (completionHandler) in
                            return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                                completionHandler(error)
                            }
                        }
                        AppRealm.queue.addOperation(op)
                    }
                }
                task.resume()
            }
        }
    }

    public static func endScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        if let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId) {
            let newScene = Scene(clone: scene)
            newScene.closedAt = Date()
            if let canonical = Scene(canonicalize: newScene), let changes = newScene.changes(from: scene) {
                let data = [
                    "Scene": changes
                ]
                try! realm.write {
                    realm.add(canonical, update: .modified)
                    realm.add(newScene, update: .modified)
                }
                let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                    completionHandler(error)
                    if error != nil {
                        let op = RequestOperation()
                        op.queuePriority = .veryHigh
                        op.request = { (completionHandler) in
                            return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                                completionHandler(error)
                            }
                        }
                        AppRealm.queue.addOperation(op)
                    }
                }
                task.resume()
            }
        }
    }

    public static func joinScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        if let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId),
           let userId = AppSettings.userId,
           let user = realm.object(ofType: User.self, forPrimaryKey: userId),
           let agencyId = AppSettings.agencyId,
           let agency = realm.object(ofType: Agency.self, forPrimaryKey: agencyId) {
            let responder = Responder()
            responder.scene = scene
            responder.user = user
            responder.agency = agency
            if let vehicleId = AppSettings.vehicleId {
                responder.vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId)
            }
            responder.arrivedAt = Date()
            let data = [
                "Responder": responder.asJSON()
            ]
            try! realm.write {
                // instantiate from JSON, this allows the Responder override of instantiate to check if the user has already joined
                realm.add(Responder.instantiate(from: responder.asJSON(), with: realm), update: .modified)
            }
            let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                completionHandler(error)
                if error != nil {
                    let op = RequestOperation()
                    op.queuePriority = .veryHigh
                    op.request = { (completionHandler) in
                        return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                            completionHandler(error)
                        }
                    }
                    AppRealm.queue.addOperation(op)
                }
            }
            task.resume()
        }
    }

    public static func addResponder(responder: Responder, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        let data = [
            "Responder": responder.asJSON()
        ]
        try! realm.write {
            // instantiate from JSON, this allows the Responder override of instantiate to check if the user has already joined
            realm.add(responder, update: .modified)
        }
        let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
            completionHandler(error)
            if error != nil {
                let op = RequestOperation()
                op.queuePriority = .veryHigh
                op.request = { (completionHandler) in
                    return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                        completionHandler(error)
                    }
                }
                AppRealm.queue.addOperation(op)
            }
        }
        task.resume()
    }

    public static func markResponderArrived(responderId: String, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        guard let responder = realm.object(ofType: Responder.self, forPrimaryKey: responderId), responder.arrivedAt == nil else {
            completionHandler(nil)
            return
        }
        try! realm.write {
            responder.arrivedAt = Date()
        }
        let data = [
            "Responder": responder.asJSON()
        ]
        let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
            completionHandler(error)
            if error != nil {
                let op = RequestOperation()
                op.queuePriority = .veryHigh
                op.request = { (completionHandler) in
                    return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                        completionHandler(error)
                    }
                }
                AppRealm.queue.addOperation(op)
            }
        }
        task.resume()
    }

    public static func markResponderDeparted(responderId: String, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        guard let responder = realm.object(ofType: Responder.self, forPrimaryKey: responderId), responder.departedAt == nil else {
            completionHandler(nil)
            return
        }
        try! realm.write {
            responder.departedAt = Date()
        }
        let data = [
            "Responder": responder.asJSON()
        ]
        let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
            completionHandler(error)
            if error != nil {
                let op = RequestOperation()
                op.queuePriority = .veryHigh
                op.request = { (completionHandler) in
                    return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                        completionHandler(error)
                    }
                }
                AppRealm.queue.addOperation(op)
            }
        }
        task.resume()
    }

    public static func assignResponder(responderId: String, role: ResponderRole?, completionHandler: ((Error?) -> Void)? = nil) {
        let realm = AppRealm.open()
        guard let responder = realm.object(ofType: Responder.self, forPrimaryKey: responderId), let scene = responder.scene,
                let role = role else { return }
        let newScene = Scene(clone: scene)
        // first remove from any existing role
        if newScene.mgsResponderId == responderId {
            newScene.mgsResponderId = nil
        }
        if newScene.triageResponderId == responderId {
            newScene.triageResponderId = nil
        }
        if newScene.treatmentResponderId == responderId {
            newScene.treatmentResponderId = nil
        }
        if newScene.stagingResponderId == responderId {
            newScene.stagingResponderId = nil
        }
        if newScene.transportResponderId == responderId {
            newScene.transportResponderId = nil
        }
        // then assign to new role
        switch role {
        case .mgs:
            newScene.mgsResponderId = responderId
        case .triage:
            newScene.triageResponderId = responderId
        case .treatment:
            newScene.treatmentResponderId = responderId
        case .staging:
            newScene.stagingResponderId = responderId
        case .transport:
            newScene.transportResponderId = responderId
        }
        if let canonical = Scene(canonicalize: newScene), let changes = newScene.changes(from: scene) {
            let data = [
                "Scene": changes
            ]
            try! realm.write {
                realm.add(canonical, update: .modified)
                realm.add(newScene, update: .modified)
            }
            let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                completionHandler?(error)
                if error != nil {
                    let op = RequestOperation()
                    op.queuePriority = .veryHigh
                    op.request = { (completionHandler) in
                        return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                            completionHandler(error)
                        }
                    }
                    AppRealm.queue.addOperation(op)
                }
            }
            task.resume()
        }
    }

    public static func leaveScene(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let realm = AppRealm.open()
        if let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId),
           let userId = AppSettings.userId,
           let responder = scene.responders.filter("user.id=%@ AND departedAt=%@", userId, NSNull()).first {
            try! realm.write {
                responder.departedAt = Date()
            }
            let data = [
                "Responder": responder.asJSON()
            ]
            let task = PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                completionHandler(error)
                if error != nil {
                    let op = RequestOperation()
                    op.queuePriority = .veryHigh
                    op.request = { (completionHandler) in
                        return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                            completionHandler(error)
                        }
                    }
                    AppRealm.queue.addOperation(op)
                }
            }
            task.resume()
        }
    }

    public static func updateScene(scene: Scene, completionHandler: ((Error?) -> Void)? = nil) {
        let canonical = Scene(clone: scene)
        canonical.id = canonical.canonicalId!
        canonical.canonicalId = nil
        let realm = AppRealm.open()
        try! realm.write {
            realm.add([scene, canonical], update: .modified)
        }
        let sceneData = ["Scene": scene.asJSON()]
        let task = PRApiClient.shared.createOrUpdateScene(data: sceneData) { (_, _, data, error) in
            let realm = AppRealm.open()
            try! realm.write {
                if let data = data, let scene = Scene.instantiate(from: data, with: realm) as? Scene {
                    realm.add(scene, update: .modified)
                }
            }
            completionHandler?(error)
            if error != nil {
                let op = RequestOperation()
                op.queuePriority = .veryHigh
                op.request = { (internalCompletionHandler) in
                    return PRApiClient.shared.createOrUpdateScene(data: sceneData) { (_, _, data, error) in
                        let realm = AppRealm.open()
                        try! realm.write {
                            if let data = data, let scene = Scene.instantiate(from: data, with: realm) as? Scene {
                                realm.add(scene, update: .modified)
                            }
                        }
                        internalCompletionHandler(error)
                    }
                }
                AppRealm.queue.addOperation(op)
            }
        }
        task.resume()
    }

    public static func connect(sceneId: String) {
        // cancel any existing task
        sceneSocket?.disconnect()
        // connect to scene socket
        sceneSocket = PRApiClient.shared.connect(sceneId: sceneId) { (socket, data, error) in
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
                AppRealm.handlePayload(data: data)
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

    public static func updateApproxPatientsCounts(sceneId: String, priority: TriagePriority?, value: Int) {
        let realm = AppRealm.open()
        if let scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId) {
            let newScene = Scene(clone: scene)
            if let priority = priority, var approxPriorityPatientsCounts = newScene.approxPriorityPatientsCounts {
                if approxPriorityPatientsCounts.count > priority.rawValue {
                    approxPriorityPatientsCounts[priority.rawValue] = value
                    newScene.approxPriorityPatientsCounts = approxPriorityPatientsCounts
                }
            } else {
                newScene.approxPatientsCount = value
            }
            if let canonical = Scene(canonicalize: newScene), let changes = newScene.changes(from: scene) {
                let data = [
                    "Scene": changes
                ]
                try! realm.write {
                    realm.add(canonical, update: .modified)
                    realm.add(newScene, update: .modified)
                }
                let op = RequestOperation()
                op.queuePriority = .veryHigh
                op.request = { (completionHandler) in
                    return PRApiClient.shared.createOrUpdateScene(data: data) { (_, _, _, error) in
                        completionHandler(error)
                    }
                }
                AppRealm.queue.addOperation(op)
            }
        }
    }

    // MARK: - Responders

    public static func getResponders(sceneId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getResponders(sceneId: sceneId) { (_, _, responders, error) in
            if let error = error {
                completionHandler(error)
            } else if let responders = responders {
                let realm = AppRealm.open()
                try! realm.write {
                    let responders = responders.map({ Responder.instantiate(from: $0, with: realm) })
                    realm.add(responders, update: .modified)
                }
                completionHandler(nil)
            }
        }
        task.resume()
    }

    // MARK: - States

    public static func getStates(search: String, completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.getStates(search: search, completionHandler: { (_, _, records, error) in
            if let error = error {
                completionHandler(error)
            } else if let records = records {
                let realm = AppRealm.open()
                try! realm.write {
                    let states = records.map({ State.instantiate(from: $0, with: realm) })
                    realm.add(states, update: .modified)
                }
                completionHandler(nil)
            }
        })
        task.resume()
    }

    // MARK: - Users

    public static func me(completionHandler: @escaping (User?, Agency?, Assignment?, Vehicle?, Scene?, [String: String]?, Error?) -> Void) {
        let task = PRApiClient.shared.me { (_, _, data, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, nil, nil, nil, error)
                }
            } else if let data = data {
                AppRealm.handlePayload(data: data)
                let realm = AppRealm.open()
                var user: User?
                var awsCredentials: [String: String]?
                if let data = data["User"] as? [String: Any], let userId = data["id"] as? String {
                    user = realm.object(ofType: User.self, forPrimaryKey: userId)
                    awsCredentials = data["awsCredentials"] as? [String: String]
                }
                var agency: Agency?
                if let data = data["Agency"] as? [[String: Any]], let agencyId = data[0]["id"] as? String {
                    agency = realm.object(ofType: Agency.self, forPrimaryKey: agencyId)
                }
                var assignment: Assignment?
                if let data = data["Assignment"] as? [String: Any], let assignmentId = data["id"] as? String {
                    assignment = realm.object(ofType: Assignment.self, forPrimaryKey: assignmentId)
                }
                var vehicle: Vehicle?
                if let data = data["Vehicle"] as? [String: Any], let vehicleId = data["id"] as? String {
                    vehicle = realm.object(ofType: Vehicle.self, forPrimaryKey: vehicleId)
                }
                var scene: Scene?
                if let data = data["Scene"] as? [[String: Any]], data.count > 0, let sceneId = data[0]["id"] as? String {
                    scene = realm.object(ofType: Scene.self, forPrimaryKey: sceneId)
                }
                completionHandler(user, agency, assignment, vehicle, scene, awsCredentials, nil)
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil, nil, nil, nil, nil, nil, ApiClientError.unexpected)
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
                let realm = AppRealm.open()
                try! realm.write {
                    let vehicles = records.map({ Vehicle.instantiate(from: $0, with: realm) })
                    realm.add(vehicles, update: .modified)
                }
                if let links = PRApiClient.parseLinkHeader(from: response), let next = links["next"] {
                    let task = PRApiClient.shared.GET(path: next, params: nil, completionHandler: vehiclesCompletionHandler)
                    task.resume()
                } else {
                    completionHandler(nil)
                }
            }
        }
        let task = PRApiClient.shared.getVehicles(completionHandler: vehiclesCompletionHandler)
        task.resume()
    }
}
