import Network
import OneSignalExtension
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    private let appGroup = "group.com.mediasis.dashboardapp.onesignal"
    private let lock = NSLock()
    private var completed = false
    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var receivedRequest: UNNotificationRequest!
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        receivedRequest = request
        self.contentHandler = contentHandler
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent
        guard
            let content = bestAttemptContent,
            let custom = request.content.userInfo["custom"] as? [String: Any],
            let data = custom["a"] as? [String: Any],
            data["type"] as? String == "new_order"
        else { finish(); return }

        attemptPrinting(data: data) { [weak self] in
            guard let self, !self.completed else { return }
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                request,
                with: content,
                withContentHandler: { _ in self.finish() }
            )
        }
    }

    override func serviceExtensionTimeWillExpire() { finish(expiring: true) }

    private func attemptPrinting(data: [String: Any], completion: @escaping () -> Void) {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let orderId = data["order_id"] as? String,
            let locationId = data["business_location_id"] as? String,
            let endpoint = data["print_endpoint"] as? String,
            let authorization = data["print_authorization"] as? String,
            defaults.bool(forKey: "app_is_active") == false,
            defaults.string(forKey: "business_location_id") == locationId,
            let printers = defaults.array(forKey: "printers") as? [[String: Any]],
            !printers.isEmpty
        else { completion(); return }

        let group = DispatchGroup()
        var printedKeys = Set(defaults.stringArray(forKey: "printed_keys") ?? [])
        for printer in printers {
            let printerId = printer["id"] as? String ?? ""
            let key = "\(locationId)|\(orderId)|\(printerId)"
            if printedKeys.contains(key) { continue }
            group.enter()
            fetchReceipt(endpoint: endpoint, authorization: authorization, printer: printer) { result in
                switch result {
                case .success(let bytes):
                    self.sendWithRetry(bytes: bytes, printer: printer) { error in
                        if let error {
                            self.saveJob(defaults, orderId, locationId, printer, "failed", error.localizedDescription)
                        } else {
                            printedKeys.insert(key)
                            self.saveJob(defaults, orderId, locationId, printer, "printed", nil)
                        }
                        group.leave()
                    }
                case .failure(let error):
                    self.saveJob(defaults, orderId, locationId, printer, "failed", error.localizedDescription)
                    group.leave()
                }
            }
        }
        group.notify(queue: .global()) {
            defaults.set(Array(printedKeys), forKey: "printed_keys")
            completion()
        }
    }

    private func fetchReceipt(
        endpoint: String,
        authorization: String,
        printer: [String: Any],
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(printError("Direccion del servicio invalida")))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "print_authorization": authorization,
            "paper_width": printer["paper_width"] as? String ?? "mm80",
            "supports_cutter": printer["supports_cutter"] as? Bool ?? true,
            "receipt_format": printer["receipt_format"] as? String ?? "visualRaster",
        ])
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error { completion(.failure(error)); return }
            guard
                let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode),
                let data
            else { completion(.failure(printError("No se pudo preparar el recibo"))); return }
            completion(.success(data))
        }.resume()
    }

    private func send(bytes: Data, printer: [String: Any], completion: @escaping (Error?) -> Void) {
        let host = NWEndpoint.Host(printer["host"] as? String ?? "")
        let rawPort = UInt16(printer["port"] as? Int ?? 9100)
        let port = NWEndpoint.Port(rawValue: rawPort) ?? NWEndpoint.Port(rawValue: 9100)!
        let connection = NWConnection(host: host, port: port, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: bytes, completion: .contentProcessed { error in
                    connection.cancel(); completion(error)
                })
            case .failed(let error):
                connection.cancel(); completion(error)
            default: break
            }
        }
        connection.start(queue: .global())
    }

    private func sendWithRetry(
        bytes: Data,
        printer: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        send(bytes: bytes, printer: printer) { firstError in
            guard firstError != nil else { completion(nil); return }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                self.send(bytes: bytes, printer: printer, completion: completion)
            }
        }
    }

    private func saveJob(
        _ defaults: UserDefaults,
        _ orderId: String,
        _ locationId: String,
        _ printer: [String: Any],
        _ status: String,
        _ error: String?
    ) {
        var jobs = defaults.array(forKey: "completed_jobs") as? [[String: Any]] ?? []
        jobs.append([
            "id": "native_\(Int(Date().timeIntervalSince1970 * 1000))_\(printer["id"] as? String ?? "")",
            "business_location_id": locationId,
            "order_id": orderId,
            "printer_id": printer["id"] as? String ?? "",
            "printer_name": printer["name"] as? String ?? "Impresora",
            "trigger": "automatic",
            "status": status,
            "attempted_at": ISO8601DateFormatter().string(from: Date()),
            "error": error ?? NSNull(),
        ])
        defaults.set(jobs, forKey: "completed_jobs")
    }

    private func finish(expiring: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        guard !completed, let handler = contentHandler else { return }
        completed = true
        if expiring, let content = bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(receivedRequest, with: content)
        }
        handler(bestAttemptContent ?? receivedRequest.content)
    }
}

private func printError(_ message: String) -> NSError {
    NSError(domain: "com.mediasis.dashboardapp.printing", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
}
