import UIKit
import FaceRecognitionKit

/// Android `EnrolledListActivity`.
final class EnrolledListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let countLabel = UILabel()
    private var people: [EnrolledPerson] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = IXColor.bg
        title = "Enrolled list"
        ScreenChrome.showInnerBar(on: self)
        FaceRecognitionClient.shared.loadDatabase()

        countLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        countLabel.textColor = IXColor.muted
        countLabel.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.text = "No enrolled people yet"
        emptyLabel.textColor = IXColor.muted
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        tableView.register(EnrolledPersonCell.self, forCellReuseIdentifier: EnrolledPersonCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(countLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenChrome.showInnerBar(on: self)
        refresh()
    }

    private func refresh() {
        FaceRecognitionClient.shared.loadDatabase()
        people = FaceRecognitionClient.shared.enrolledPeople()
        tableView.reloadData()
        let empty = people.isEmpty
        emptyLabel.isHidden = !empty
        tableView.isHidden = empty
        countLabel.isHidden = empty
        countLabel.text = "\(people.count) enrolled"
    }

    private func confirmDelete(_ person: EnrolledPerson) {
        let alert = UIAlertController(title: "Delete person", message: person.name, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            FaceRecognitionClient.shared.removeEnrolled(ids: [person.id])
            self?.refresh()
        })
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        people.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: EnrolledPersonCell.reuseId,
            for: indexPath
        ) as! EnrolledPersonCell
        let person = people[indexPath.row]
        cell.configure(
            person: person,
            thumbnail: FaceRecognitionClient.shared.thumbnail(for: person),
            onDelete: { [weak self] in self?.confirmDelete(person) }
        )
        return cell
    }
}

private final class EnrolledPersonCell: UITableViewCell {
    static let reuseId = "EnrolledPersonCell"
    private let thumb = UIImageView()
    private let nameLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private var onDelete: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = IXColor.surface
        contentView.layer.cornerRadius = 10
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = IXColor.stroke.cgColor
        contentView.clipsToBounds = true

        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 28
        thumb.backgroundColor = IXColor.overlay
        thumb.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.textColor = IXColor.text
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = IXColor.statusError
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumb)
        contentView.addSubview(nameLabel)
        contentView.addSubview(deleteButton)
        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 56),
            thumb.heightAnchor.constraint(equalToConstant: 56),
            nameLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.insetBy(dx: 0, dy: 4)
    }

    func configure(person: EnrolledPerson, thumbnail: UIImage?, onDelete: @escaping () -> Void) {
        nameLabel.text = person.name
        thumb.image = thumbnail
        self.onDelete = onDelete
    }

    @objc private func deleteTapped() { onDelete?() }
}
