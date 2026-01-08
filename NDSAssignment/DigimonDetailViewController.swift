//
//  DigimonDetailViewController.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import UIKit

class DigimonDetailViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var infoStackView: UIStackView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var digimonID: Int = 0
    private var digimonDetail: DigimonDetail?
    private var networkManager: NetworkManagerProtocol = NetworkManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDetail()
    }
    
    private func setupUI() {
        detailView.layer.cornerRadius = 20
        detailView.layer.maskedCorners = [
            .layerMinXMinYCorner, // kiri atas
            .layerMaxXMinYCorner  // kanan atas
        ]
        detailView.layer.masksToBounds = true
        
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        
        nameLabel.font = .systemFont(ofSize: 32, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        
        infoStackView.axis = .vertical
        infoStackView.spacing = 16
        infoStackView.distribution = .fill
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .large
    }
    
    private func loadDetail() {
        loadingIndicator.startAnimating()
        
        networkManager.fetchDigimonDetail(id: digimonID) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let detail):
                    self.digimonDetail = detail
                    self.displayDetail(detail)
                    
                case .failure(let error):
                    self.showError(error)
                }
            }
        }
    }
    
    private func displayDetail(_ detail: DigimonDetail) {
        title = detail.name
        nameLabel.text = detail.name
        
        if let imageURLString = detail.images?.first?.href,
           let imageURL = URL(string: imageURLString) {
            imageView.loadImage(from: imageURL)
        }
        
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let xAntibody = detail.xAntibody, xAntibody {
            addXAntibodyBadge()
        }
        
        let hasLevel = detail.levels?.isEmpty == false
        let hasType = detail.types?.isEmpty == false
        let hasAttribute = detail.attributes?.isEmpty == false
        
        if hasLevel || hasType || hasAttribute {
            addBasicInfoSection(detail: detail)
        }
        
        if let descriptions = detail.descriptions,
           let englishDesc = descriptions.first(where: { $0.language == "en_us" })?.description,
           !englishDesc.isEmpty {
            addDescriptionSection(description: englishDesc)
        }
        
        if let priorEvolutions = detail.priorEvolutions, !priorEvolutions.isEmpty {
            addEvolutionSection(evolutions: priorEvolutions, title: "Prior Evolutions", emoji: "⬅️")
        }
        
        if let nextEvolutions = detail.nextEvolutions, !nextEvolutions.isEmpty {
            addEvolutionSection(evolutions: nextEvolutions, title: "Next Evolutions", emoji: "➡️")
        }
        
        if let fields = detail.fields, !fields.isEmpty {
            addFieldsSection(fields: fields)
        }
        
        if let skills = detail.skills, !skills.isEmpty {
            addSkillsSection(skills: skills)
        }
    }
    
    private func addXAntibodyBadge() {
        let badgeView = UIView()
        badgeView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.15)
        badgeView.layer.cornerRadius = 8
        
        let label = UILabel()
        label.text = "🛡️ X-Antibody"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .systemPurple
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        badgeView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -8)
        ])
        
        infoStackView.addArrangedSubview(badgeView)
    }
    
    private func addBasicInfoSection(detail: DigimonDetail) {
        let containerView = createCardContainer()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = createSectionTitle(text: "Basic Information")
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentStack)
        
        if let levels = detail.levels, !levels.isEmpty {
            let levelText = levels.compactMap { $0.level }.joined(separator: ", ")
            if !levelText.isEmpty {
                contentStack.addArrangedSubview(createInfoRow(icon: "📊", title: "Level", value: levelText))
            }
        }
        
        if let types = detail.types, !types.isEmpty {
            let typeText = types.compactMap { $0.type }.joined(separator: ", ")
            if !typeText.isEmpty {
                contentStack.addArrangedSubview(createInfoRow(icon: "🏷️", title: "Type", value: typeText))
            }
        }
        
        if let attributes = detail.attributes, !attributes.isEmpty {
            let attrText = attributes.compactMap { $0.attribute }.joined(separator: ", ")
            if !attrText.isEmpty {
                contentStack.addArrangedSubview(createInfoRow(icon: "⚡", title: "Attribute", value: attrText))
            }
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    private func addEvolutionSection(evolutions: [Evolution], title: String, emoji: String) {
        let containerView = createCardContainer()
        
        let titleLabel = createSectionTitle(text: "\(emoji) \(title)")
        containerView.addSubview(titleLabel)
        
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(stackView)
        containerView.addSubview(scrollView)
        
        for evolution in evolutions {
            let evolutionView = createEvolutionView(evolution: evolution)
            stackView.addArrangedSubview(evolutionView)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            scrollView.heightAnchor.constraint(equalToConstant: 140),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    private func createEvolutionView(evolution: Evolution) -> UIView {
        let container = UIView()
        container.backgroundColor = .tertiarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.loadImage(from: evolution.imageURL, placeholder: UIImage(systemName: "photo"))
        
        let nameLabel = UILabel()
        nameLabel.text = evolution.digimon
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(imageView)
        container.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 100),
            
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func addFieldsSection(fields: [Field]) {
        let containerView = createCardContainer()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = createSectionTitle(text: "Fields")
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentStack)
        
        for field in fields {
            if let fieldName = field.field, !fieldName.isEmpty {
                let fieldRow = createFieldRow(field: field)
                contentStack.addArrangedSubview(fieldRow)
            }
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    private func addSkillsSection(skills: [Skill]) {
        let containerView = createCardContainer()
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = createSectionTitle(text: "Skills & Attacks")
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentStack)
        
        for skill in skills {
            if let skillName = skill.skill, !skillName.isEmpty {
                let skillCard = createSkillCard(skill: skill)
                contentStack.addArrangedSubview(skillCard)
            }
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    private func addDescriptionSection(description: String) {
        let containerView = createCardContainer()
        
        let titleLabel = createSectionTitle(text: "Description")
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 15, weight: .regular)
        descLabel.textColor = .label
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    private func createCardContainer() -> UIView {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.05
        return view
    }
    
    private func createSectionTitle(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createInfoRow(icon: String, title: String, value: String) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .tertiarySystemGroupedBackground
        rowView.layer.cornerRadius = 10
        
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 18)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rowView.addSubview(iconLabel)
        rowView.addSubview(titleLabel)
        rowView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 12),
            iconLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 12),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: iconLabel.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -12),
            valueLabel.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 12),
            valueLabel.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -12),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            
            rowView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        return rowView
    }
    
    private func createFieldRow(field: Field) -> UIView {
        let rowView = UIView()
        rowView.backgroundColor = .tertiarySystemGroupedBackground
        rowView.layer.cornerRadius = 10
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let imageURLString = field.image, let imageURL = URL(string: imageURLString) {
            imageView.loadImage(from: imageURL, placeholder: UIImage(systemName: "photo"))
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray
        }
        
        let nameLabel = UILabel()
        nameLabel.text = field.field ?? "Unknown Field"
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rowView.addSubview(imageView)
        rowView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -12),
            
            rowView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        
        return rowView
    }
    
    private func createSkillCard(skill: Skill) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .tertiarySystemGroupedBackground
        cardView.layer.cornerRadius = 12
        
        let nameLabel = UILabel()
        nameLabel.text = skill.skill ?? "Unknown Skill"
        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = .systemBlue
        nameLabel.numberOfLines = 0
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descLabel = UILabel()
        let description = skill.description ?? skill.translation ?? "No description available"
        descLabel.text = description
        descLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(nameLabel)
        cardView.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            descLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            descLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            descLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
        
        return cardView
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadDetail()
        })
        
        alert.addAction(UIAlertAction(title: "Back", style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}
