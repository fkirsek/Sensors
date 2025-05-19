//
//  ViewController.swift
//  sensors
//
//  Created by Filip Kirsek on 2025-05-19.
//

import UIKit
import PureLayout
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    let circle = UIView()
    let square = UIView()
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()

    override func loadView() {
        view = UIView()

        view.addSubview(circle)
        view.addSubview(square)

        square.autoCenterInSuperview()
        square.backgroundColor = .blue
        square.autoSetDimensions(to: CGSize(width: 50, height: 50))

        circle.autoCenterInSuperview()
        circle.autoSetDimensions(to: CGSize(width: 50, height: 50))
        circle.backgroundColor = .red
        circle.layer.cornerRadius = 25

        setupBindings()
    }

    func setupBindings() {
        viewModel.showSquareTimer
            .bind(to: square.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showCircleTimer
            .bind(to: circle.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.currentLookAtPoint.subscribe(onNext: { _ in

        }).disposed(by: disposeBag)

        viewModel.accelerationRelay.subscribe(onNext: { _ in

        }).disposed(by: disposeBag)
    }

}

