import Foundation
import UIKit

/// File browser containing navigation controller.
open class FileBrowser: UINavigationController {
    
    var viewController: ViewController?
    
    public convenience init() {
        self.init(username: nil)
    }
    
    /// Initialise file browser with a username.
    ///
    /// - Parameter username: The username to use for fetching documents.
    public convenience init(username: String?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSHomeDirectory()
        let initialPath = URL(fileURLWithPath: documentsPath)
        let viewController = ViewController(initialPath: initialPath, showCancelButton: true, username: username)
        self.init(rootViewController: viewController)
        self.view.backgroundColor = UIColor.white
        self.viewController = viewController
    }
}
