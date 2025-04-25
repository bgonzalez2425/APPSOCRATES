import UIKit

class LoginViewController: UIViewController {
    
    private let textField = UITextField()
    private let button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Configurar el campo de texto (nombre del dispositivo o usuario)
        textField.placeholder = "Nombre del dispositivo (modifica si deseas)"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)
        
        // Configurar el botón
        button.setTitle("Continuar", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        // Restricciones
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            textField.widthAnchor.constraint(equalToConstant: 200),
            
            button.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        
        // Obtener el nombre del dispositivo y establecerlo en el campo de texto
        let deviceName = UIDevice.current.name
        textField.text = deviceName
    }
    
    @objc func continueTapped() {
        guard let username = textField.text, !username.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Por favor, introduce un nombre", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Sanitizar el nombre de usuario (reemplazar espacios por guiones bajos y eliminar caracteres no válidos)
        let sanitizedUsername = username.replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        
        // Navegar a FileBrowser con el nombre de usuario sanitizado
        let fileBrowser = FileBrowser(username: sanitizedUsername)
        navigationController?.pushViewController(fileBrowser, animated: true)
    }
}
