import UIKit
import WebKit

class ViewController: UIViewController {
    /// Encapsulates a demo with a title and subtitle for the cell and `BottomSheet` headers and a closure to present it.
    struct DemoAction {
        let title: String
        let subtitle: String
        let actionHandler: (DemoAction) -> Void
    }
    
    private var demoActions: [DemoAction]!
    private var bottomSheet: BottomSheet?
    private var selectedAction: DemoAction?
    private var tableView = UITableView()
    private var positionChangeClosure: ((CGFloat) -> Void)!
    private var tableViewBottomConstraint: NSLayoutConstraint!
    private var demoTableViewDataSource = DemoTableViewDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = "BottomSheet Demo"
        self.setUpTableView()
        self.setUpActions()
    }
    
    private func presentAction(_ action: DemoAction) {
        action.actionHandler(action)
    }
    
    private func setUpActions() {
        self.demoActions = [
            DemoAction(title: "Vertical StackView", subtitle: "Scrolls Vertically")
            { [weak self] action in
                guard let self = self else {
                    return
                }
                
                let contentView = UIStackView()
                contentView.axis = .vertical
                for i in 0...100 {
                    let textLabel = UILabel()
                    textLabel.text = "Hello \(i)"
                    contentView.addArrangedSubview(textLabel)
                }
                contentView.backgroundColor = .red
                self.bottomSheet = BottomSheet(title: action.title,
                                                subtitle: action.subtitle, contentView: contentView)
                self.bottomSheet?.bottomSheetDismissedClosure = {
                    self.bottomSheet = nil
                    self.selectedAction = nil
                }
                self.bottomSheet?.bottomSheetPositionChangedClosure = self.positionChangeClosure
                self.bottomSheet?.present(in: self.view)
                self.selectedAction = action
            },
            DemoAction(title: "Horizontal StackView", subtitle: "Scrolls Horizontally")
            { [weak self] action in
                guard let self = self else {
                    return
                }
                
                let contentView = UIStackView()
                contentView.axis = .horizontal
                for i in 0...100 {
                    let textLabel = UILabel()
                    textLabel.text = "Hello \(i)"
                    contentView.addArrangedSubview(textLabel)
                }
                contentView.backgroundColor = .red
                self.bottomSheet = BottomSheet(title: action.title,
                                                subtitle: action.subtitle, contentView: contentView)
                self.bottomSheet?.bottomSheetDismissedClosure = {
                    self.bottomSheet = nil
                    self.selectedAction = nil
                }
                self.bottomSheet?.bottomSheetPositionChangedClosure = self.positionChangeClosure
                self.bottomSheet?.present(in: self.view)
                self.selectedAction = action
            },
            DemoAction(title: "TableView", subtitle: "With lots of cells")
            { [weak self] action in
                guard let self = self else {
                    return
                }
                
                let contentView = UITableView()
                contentView.dataSource = self.demoTableViewDataSource
                self.bottomSheet = BottomSheet(title: action.title,
                                                subtitle: action.subtitle, contentView: contentView)
                self.bottomSheet?.bottomSheetDismissedClosure = {
                    self.bottomSheet = nil
                    self.selectedAction = nil
                }
                self.bottomSheet?.bottomSheetPositionChangedClosure = self.positionChangeClosure
                self.bottomSheet?.present(in: self.view)
                self.selectedAction = action
            },
            DemoAction(title: "Webview", subtitle: "Apple.com")
            { [weak self] action in
                guard let self = self else {
                    return
                }
                
                let contentView = WKWebView()
                let myURL = URL(string:"https://www.apple.com")
                let myRequest = URLRequest(url: myURL!)
                contentView.load(myRequest)
                self.bottomSheet = BottomSheet(title: action.title,
                                                subtitle: action.subtitle, contentView: contentView)
                self.bottomSheet?.bottomSheetDismissedClosure = {
                    self.bottomSheet = nil
                    self.selectedAction = nil
                }
                self.bottomSheet?.bottomSheetPositionChangedClosure = self.positionChangeClosure
                self.bottomSheet?.present(in: self.view)
                self.selectedAction = action
            },
        ]
    }
    
    private func setUpTableView() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        
        self.tableViewBottomConstraint = self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableViewBottomConstraint
        ])
        
        self.positionChangeClosure = { offset in
            self.tableViewBottomConstraint.constant =
                -(self.view.safeAreaLayoutGuide.layoutFrame.height - offset + self.view.safeAreaInsets.bottom)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.demoActions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
            UITableViewCell(style: .default, reuseIdentifier: "cell")
        let action = self.demoActions[indexPath.row]
        cell.textLabel?.text = action.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let bottomSheet = self.bottomSheet,
           let selectedAction = self.selectedAction {
            let newAction = self.demoActions[indexPath.row]
            
            // Just dismiss if it's the same demo
            if newAction.title == selectedAction.title {
                bottomSheet.dismiss()
                return
            }
            
            // Dismiss then present if it's a new demo
            bottomSheet.bottomSheetDismissedClosure = {
                self.bottomSheet = nil
                self.selectedAction = nil
                self.presentAction(self.demoActions[indexPath.row])
            }
            bottomSheet.dismiss()
            return
        }
        // Nothing previously selected so just show the bottomSheet
        self.presentAction(self.demoActions[indexPath.row])
    }

}

class DemoTableViewDataSource: NSObject, UITableViewDataSource {
    private let identifier = "democell"
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        cell.textLabel?.text = "Section: \(indexPath.section)"
        cell.detailTextLabel?.text = "Row:\(indexPath.row)"
        return cell
    }

    
}
