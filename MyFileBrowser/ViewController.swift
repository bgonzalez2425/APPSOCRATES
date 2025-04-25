import UIKit

class ViewController: UITableViewController {
    
    // Etiqueta para el nombre del dispositivo
    private let deviceNameLabel = UILabel()
    
    // Lista de documentos
    private var documents: [String] = []
    
    // Propiedades requeridas por FileBrowser
    var initialPath: URL
    var showCancelButton: Bool
    var username: String?
    
    init(initialPath: URL, showCancelButton: Bool, username: String? = nil) {
        self.initialPath = initialPath
        self.showCancelButton = showCancelButton
        self.username = username
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.initialPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSHomeDirectory())
        self.showCancelButton = true
        self.username = nil
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar la interfaz programáticamente
        setupUI()
        
        // Obtener el nombre del dispositivo
        let deviceName = UIDevice.current.name
        deviceNameLabel.text = "Nombre del dispositivo: \(deviceName)"
        
        // Usar el nombre de usuario proporcionado o extraerlo del nombre del dispositivo si no se proporcionó
        let userName = username ?? extractUserName(from: deviceName)
        
        // Obtener documentos desde el servidor
        fetchDocuments(userName: userName) { [weak self] documentNames, error in
            if let error = error {
                self?.showAlert(message: "Error al obtener documentos: \(error.localizedDescription)")
                return
            }
            if let documentNames = documentNames {
                self?.documents = documentNames
                self?.tableView.reloadData()
            }
        }
    }
    
    // Configurar la interfaz programáticamente
    private func setupUI() {
        // Configurar la vista principal
        view.backgroundColor = .white
        
        // Configurar la etiqueta del nombre del dispositivo
        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceNameLabel.textAlignment = .center
        deviceNameLabel.numberOfLines = 0
        view.addSubview(deviceNameLabel)
        
        // Configurar la tabla
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Añadir restricciones
        NSLayoutConstraint.activate([
            // Restricciones para la etiqueta
            deviceNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            deviceNameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            deviceNameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            deviceNameLabel.heightAnchor.constraint(equalToConstant: 50),
            
            // Restricciones para la tabla
            tableView.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        
        // Registrar la celda para la tabla
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
    }
    
    // Función para extraer el nombre del usuario del nombre del dispositivo
    private func extractUserName(from deviceName: String) -> String {
        // Ejemplo: "iPad de Juan" -> "Juan"
        let components = deviceName.split(separator: " ")
        if components.count >= 3, components[0] == "iPad", components[1] == "de" {
            return String(components[2])
        }
        // Si el formato no coincide, usa el nombre completo del dispositivo
        return deviceName
    }
    
    // Función para obtener documentos desde el servidor
    private func fetchDocuments(userName: String, completion: @escaping ([String]?, Error?) -> Void) {
        let urlString = "http://192.168.1.100:3000/documents/\(userName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"]))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Manejar errores de red
            if let error = error {
                completion(nil, error)
                return
            }
            
            // Asegurarnos de que data no sea nil
            guard let data = data else {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibió data"]))
                return
            }
            
            // Parsear el JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let documentNames = json["documents"] as? [String] {
                    completion(documentNames, nil)
                } else {
                    completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al parsear respuesta"]))
                }
            } catch {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al parsear JSON: \(error.localizedDescription)"]))
            }
            }.resume()
    }
    
    // Función para descargar y abrir un documento al seleccionarlo
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = documents[indexPath.row]
        let userName = username ?? extractUserName(from: UIDevice.current.name)
        let urlString = "http://192.168.1.100:3000/documents/\(userName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")/\(document.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        
        // Mostrar un alerta con opciones: Abrir o Descargar
        let alert = UIAlertController(title: "Opciones", message: "Selecciona una acción para el archivo: \(document)", preferredStyle: .actionSheet)
        
        // Opción para abrir el archivo
        alert.addAction(UIAlertAction(title: "Abrir", style: .default, handler: { _ in
            self.openFile(from: url, document: document)
        }))
        
        // Opción para descargar el archivo
        alert.addAction(UIAlertAction(title: "Descargar", style: .default, handler: { _ in
            self.downloadFile(from: url, document: document)
        }))
        
        // Opción para cancelar
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        // Presentar el alerta
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = tableView
            popoverController.sourceRect = tableView.rectForRow(at: indexPath)
        }
        present(alert, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Función para abrir un archivo
    private func openFile(from url: URL, document: String) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Error al descargar el archivo: \(error?.localizedDescription ?? "Desconocido")")
                }
                return
            }
            
            // Mover el archivo a un directorio temporal
            let tempDir = FileManager.default.temporaryDirectory
            let destinationURL = tempDir.appendingPathComponent(document)
            try? FileManager.default.moveItem(at: localURL, to: destinationURL)
            
            // Abrir el archivo
            DispatchQueue.main.async {
                let documentController = UIDocumentInteractionController(url: destinationURL)
                documentController.delegate = self
                documentController.presentPreview(animated: true)
            }
        }
        downloadTask.resume()
    }
    
    // Función para descargar un archivo
    private func downloadFile(from url: URL, document: String) {
        let downloadTask = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                DispatchQueue.main.async {
                    self.showAlert(message: "Error al descargar el archivo: \(error?.localizedDescription ?? "Desconocido")")
                }
                return
            }
            
            // Obtener el directorio de documentos del usuario
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    self.showAlert(message: "No se pudo acceder al directorio de documentos")
                }
                return
            }
            
            // Crear la URL de destino en el directorio de documentos
            let destinationURL = documentsDirectory.appendingPathComponent(document)
            
            // Mover el archivo al directorio de documentos
            do {
                // Si el archivo ya existe, eliminarlo primero
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                
                DispatchQueue.main.async {
                    self.showAlert(message: "Archivo descargado exitosamente en el directorio de documentos: \(document)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(message: "Error al guardar el archivo: \(error.localizedDescription)")
                }
            }
        }
        downloadTask.resume()
    }
    
    // Mostrar alertas para errores o mensajes
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Mensaje", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
        let document = documents[indexPath.row]
        cell.textLabel?.text = document
        return cell
    }
}

// MARK: - UIDocumentInteractionControllerDelegate
extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
