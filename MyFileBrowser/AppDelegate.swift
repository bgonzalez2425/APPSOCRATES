import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [String: Any]?) -> Bool {
        // Crear la ventana principal
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Inicializar LoginViewController como el controlador raíz dentro de un UINavigationController
        let loginViewController = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginViewController)
        window?.rootViewController = navigationController
        
        // Hacer la ventana visible
        window?.makeKeyAndVisible()
        
        return true
    }
}
