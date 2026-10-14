import NewSDK
import UIKit

/// Lists the identity fields and card images returned by the SDK in a `KycResultViewModel`.
final class ResultViewController: UITableViewController {

    private let rows: [(String, String?)]
    private let images: [(String, UIImage?)]

    init(result: KycResultViewModel) {
        rows = [
            ("CIN", result.cin),
            ("First name", result.firstName),
            ("Last name", result.lastName),
            ("Gender", result.gender),
            ("Birth date", result.birthDate),
            ("Birth city", result.birthCity),
            ("Expiry date", result.dateExpire),
            ("Address", result.adress),
            ("Father", result.fatherName),
            ("Mother", result.motherName),
        ]
        images = [("Recto", result.rectoImage), ("Verso", result.versoImage)]
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan result"
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "Identity" : "Images"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? rows.count : images.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none
        if indexPath.section == 0 {
            let row = rows[indexPath.row]
            cell.textLabel?.text = row.0
            cell.detailTextLabel?.text = (row.1?.isEmpty == false) ? row.1 : "—"
        } else {
            let row = images[indexPath.row]
            let imageView = UIImageView(image: row.1)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(imageView)
            let label = UILabel()
            label.text = row.0
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                label.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                imageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
                imageView.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                imageView.heightAnchor.constraint(equalToConstant: 180),
            ])
        }
        return cell
    }
}
