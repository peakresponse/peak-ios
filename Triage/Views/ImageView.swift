//
//  ImageView.swift
//  Triage
//
//  Created by Francis Li on 9/28/20.
//  Copyright © 2020 Francis Li. All rights reserved.
//

import UIKit

class ImageView: UIView {
    weak var imageView: UIImageView!
    weak var activityIndicatorView: UIActivityIndicatorView!

    var imageURL: String? {
        didSet { loadImage() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .bgBackground

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leftAnchor.constraint(equalTo: leftAnchor),
            imageView.rightAnchor.constraint(equalTo: rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.imageView = imageView

        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.activityIndicatorView = activityIndicatorView
    }

    private func loadImage() {
        if let imageURL = imageURL {
            activityIndicatorView.startAnimating()
            DispatchQueue.global(qos: .default).async { [weak self] in
                if let url = URL(string: imageURL),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if self.imageURL == imageURL {
                            self.activityIndicatorView.stopAnimating()
                            self.imageView.image = image
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.activityIndicatorView.stopAnimating()
                    }
                }
            }
        } else {
            imageView.image = nil
            activityIndicatorView.stopAnimating()
        }
    }
}
