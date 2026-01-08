//
//  DigimonListViewController.swift
//  NDSAssignment
//
//  Created by Ardennata Winarno on 06/01/26.
//

import UIKit

class DigimonListViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyStateLabel: UILabel!
        
    private var digimons: [Digimon] = []
    private var currentPage = 0
    private var isLoading = false
    private var hasMorePages = true
    private let pageSize = 8
    private var searchTimer: Timer?
    private var currentSearchText: String?
        
    private var networkManager: NetworkManagerProtocol = NetworkManager.shared
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDigimons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
        
    private func setupUI() {
        title = "Digimon"
            
        searchBar.delegate = self
        searchBar.placeholder = "Search by name, type, level, attribute, field..."
        searchBar.showsCancelButton = false
            
        collectionView.delegate = self
        collectionView.dataSource = self
            
        let nib = UINib(nibName: "DigimonCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "DigimonCell")
            
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
            
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .large
            
        emptyStateLabel.isHidden = true
    }
        
    private func loadDigimons(reset: Bool = false) {
        if !reset {
            guard !isLoading, hasMorePages else { return }
        } else {
            if isLoading {
                isLoading = false
            }
            hasMorePages = true
            currentPage = 0
        }
                
        isLoading = true
                
        if reset || digimons.isEmpty {
            loadingIndicator.startAnimating()
            emptyStateLabel.isHidden = true
        }
            
        networkManager.fetchDigimons(page: currentPage, pageSize: pageSize, searchText: currentSearchText) { [weak self] result in
            guard let self = self else { return }
                
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadingIndicator.stopAnimating()
                    
                switch result {
                case .success(let response):
                    if reset {
                        self.digimons = response.content
                    } else {
                        self.digimons.append(contentsOf: response.content)
                    }
                        
                    if response.content.count < self.pageSize {
                        self.hasMorePages = false
                    }
                        
                    self.currentPage += 1
                    
                    if reset {
                        self.collectionView.reloadData()
                        self.collectionView.collectionViewLayout.invalidateLayout()
                    } else {
                        self.collectionView.reloadData()
                    }
                        
                    self.emptyStateLabel.isHidden = !self.digimons.isEmpty
                    if self.digimons.isEmpty {
                        if let searchText = self.currentSearchText, !searchText.isEmpty {
                            self.emptyStateLabel.text = "No Digimon found for '\(searchText)'"
                        } else {
                            self.emptyStateLabel.text = "No Digimon found"
                        }
                    }
                        
                case .failure(let error):
                    self.showError(error)
                    if self.digimons.isEmpty {
                        self.emptyStateLabel.isHidden = false
                        self.emptyStateLabel.text = "Failed to load data"
                    }
                }
            }
        }
    }
        
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
            
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadDigimons(reset: true)
        })
            
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
        present(alert, animated: true)
    }
        
    deinit {
        searchTimer?.invalidate()
    }
}

extension DigimonListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return digimons.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DigimonCell", for: indexPath) as? DigimonCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: digimons[indexPath.item])
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 12
        let spacing: CGFloat = 12
        
        let collectionViewWidth = collectionView.bounds.width
        guard collectionViewWidth > 0 else {
            return CGSize(width: 150, height: 180)
        }
        
        let availableWidth = collectionViewWidth - (padding * 2) - spacing
        let width = floor(availableWidth / 2)
        
        let imageHeight = width * 0.85
        let labelHeight: CGFloat = 40
        let totalHeight = imageHeight + labelHeight
        
        return CGSize(width: width, height: totalHeight)
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let digimon = digimons[indexPath.item]
        performSegue(withIdentifier: "showDetail", sender: digimon)
    }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
            
        if offsetY > contentHeight - height - 200, !isLoading, hasMorePages {
            loadDigimons()
        }
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
           let detailVC = segue.destination as? DigimonDetailViewController,
           let digimon = sender as? Digimon {
            detailVC.digimonID = digimon.id
        }
    }
}

extension DigimonListViewController: UISearchBarDelegate {
        
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        
        searchBar.showsCancelButton = !searchText.isEmpty
            
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performSearch(searchText)
        }
    }
        
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch(searchBar.text)
    }
        
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        currentSearchText = nil
        loadDigimons(reset: true)
    }
        
    private func performSearch(_ text: String?) {
        if let text = text, !text.isEmpty {
            currentSearchText = text
        } else {
            currentSearchText = nil
        }
        
        loadDigimons(reset: true)
    }
}
