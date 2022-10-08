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
            AppRealm.main.refresh()
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
            Procedure.self, Report.self, Responder.self, Response.self, Scene.self, ScenePin.self, Signature.self, Situation.self, State.self,
            Time.self, User.self, Vehicle.self, Vital.self
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
                Response.self,
                Situation.self,
                State.self,
                Time.self,
                User.self,
                Vehicle.self,
                Vital.self,
                // models with dependencies on above in dependency order
                Disposition.self,
                Responder.self,
                Signature.self,
                Scene.self,
                Incident.self,
                Dispatch.self,
                // report has dependencies on all of above
                Report.self
            ] {
                var objs: [Base]?
                if let records = data?[String(describing: model)] as? [[String: Any]] {
                    objs = records.map { model.instantiate(from: $0) }
                } else if let record = data?[String(describing: model)] as? [String: Any] {
                    objs = [model.instantiate(from: record)]
                }
                if let objs = objs {
                    realm.add(objs, update: .modified)
                    // special case handling for Scene, which we reference as both canonical top-level and current dependent records
                    if let objs = objs as? [Scene] {
                        realm.add(objs.compactMap { Scene(current: $0) }, update: .modified)
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
        let task = PRApiClient.shared.createAssignment(data: data) { (_, _, data, error) in
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
        let task = PRApiClient.shared.getFacilities(lat: lat, lng: lng, search: search, type: type, completionHandler: { (_, _, records, error) in
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

    public static func fetchFacilities(payload: [String: [String]], completionHandler: ((Error?) -> Void)? = nil) {
        let task = PRApiClient.shared.fetchFacilities(payload: payload) { (_, _, records, error) in
            if let error = error {
                completionHandler?(error)
            } else if let records = records {
                let facilities = records.map { Facility.instantiate(from: $0)}
                let realm = AppRealm.open()
                try! realm.write {
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
                    realm.add(data.map { Form.instantiate(from: $0) }, update: .modified)
                }
                completionHandler?(nil)
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
        let task = PRApiClient.shared.getPatients(sceneId: sceneId, completionHandler: { (_, _, records, error) in
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
        let task = PRApiClient.shared.getPatient(idOrPin: idOrPin) { (_, _, record, error) in
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
            return PRApiClient.shared.createOrUpdatePatient(data: data) { (_, _, record, error) in
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
        let data = report.canonicalize(from: parent)
        try! realm.write {
            realm.add(report, update: .modified)
            if let canonicalId = report.canonicalId {
                let canonical = Report(value: report)
                canonical.id = canonicalId
                canonical.canonicalId = nil
                canonical.parentId = nil
                canonical.currentId = report.id
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
            return PRApiClient.shared.createOrUpdateReport(data: data) { (_, _, _, error) in
                completionHandler(error)
            }
        }
        queue.addOperation(op)
    }

    // MARK: - Scene

    public static func startScene(sceneId: String, completionHandler: @escaping (String?, Error?) -> Void) {
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
            if let canonicalId = newScene.canonicalId, let changes = newScene.changes(from: scene) {
                let canonical = Scene(value: newScene)
                canonical.id = canonicalId
                canonical.canonicalId = nil
                canonical.parentId = nil
                canonical.currentId = newScene.id
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
            if let canonicalId = newScene.canonicalId, let changes = newScene.changes(from: scene) {
                let data = [
                    "Scene": changes
                ]
                try! realm.write {
                    let canonical = Scene(value: newScene)
                    canonical.id = canonicalId
                    canonical.canonicalId = nil
                    canonical.parentId = nil
                    canonical.currentId = newScene.id
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
        if let canonicalId = newScene.canonicalId, let changes = newScene.changes(from: scene) {
            let data = [
                "Scene": changes
            ]
            try! realm.write {
                let canonical = Scene(value: newScene)
                canonical.id = canonicalId
                canonical.canonicalId = nil
                canonical.parentId = nil
                canonical.currentId = newScene.id
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
                            return PRApiClient.shared.updateScene(data: [
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
        let task = PRApiClient.shared.getScenes { (_, _, records, error) in
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
        let task = PRApiClient.shared.createOrUpdateScene(data: ["Scene": scene.asJSON()]) { (_, _, data, error) in
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
        let task = PRApiClient.shared.getScene(sceneId: sceneId) { (_, _, data, error) in
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
            return PRApiClient.shared.addScenePin(sceneId: sceneId, data: data, completionHandler: completionHandler)
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
            return PRApiClient.shared.removeScenePin(sceneId: sceneId, scenePinId: scenePinId, completionHandler: completionHandler)
        }
        queue.addOperation(op)
    }

    public static func transferScene(sceneId: String, userId: String, agencyId: String, completionHandler: @escaping (Error?) -> Void) {
        let task = PRApiClient.shared.transferScene(sceneId: sceneId, userId: userId, agencyId: agencyId) { (error) in
            completionHandler(error)
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
            if let canonicalId = newScene.canonicalId, let changes = newScene.changes(from: scene) {
                let data = [
                    "Scene": changes
                ]
                try! realm.write {
                    let canonical = Scene(value: newScene)
                    canonical.id = canonicalId
                    canonical.canonicalId = nil
                    canonical.parentId = nil
                    canonical.currentId = newScene.id
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
                let vehicles = records.map({ Vehicle.instantiate(from: $0) })
                let realm = AppRealm.open()
                try! realm.write {
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
