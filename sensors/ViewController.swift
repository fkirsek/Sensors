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
import simd

class ViewController: UIViewController {

    let circle = UIView()
    let square = UIView()
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()

    let graphLayer = CAShapeLayer()
    var points: [CGPoint] = []
    let timeIntervalXModifier = 100.0

    let appStart = Date()

    override func loadView() {
        setupBasicViews()
        setupBindings()
    }

    private func setupBasicViews() {
        view = UIView()
        view.backgroundColor = .white

        view.addSubview(circle)
        view.addSubview(square)

        square.autoCenterInSuperview()
        square.backgroundColor = .blue
        square.autoSetDimensions(to: CGSize(width: 50, height: 50))

        circle.autoCenterInSuperview()
        circle.autoSetDimensions(to: CGSize(width: 50, height: 50))
        circle.backgroundColor = .red
        circle.layer.cornerRadius = 25
    }

    private func drawGraph() {
        let width = view.frame.width
        let height = view.frame.height

        let path = UIBezierPath()
        path.move(to: CGPointZero)
        let maxCount = Int(width * 0.5 / (viewModel.updateInterval * timeIntervalXModifier) )


        //TODO: Clunky, move to ViewModel?
        let graphPointsSlice = points.suffix(maxCount)
        let startInterval = graphPointsSlice.first?.x ?? 0
        let graphPoints = graphPointsSlice.map { CGPoint(x: $0.x - startInterval, y: $0.y)  }

        graphPoints.forEach { path.addLine(to: $0) }
        path.move(to: CGPointZero)
        path.close()

        let frame = CGRect(x: 0, y: 0, width: width / 2, height: height / 4)
        graphLayer.frame = frame
        graphLayer.backgroundColor = UIColor.lightGray.cgColor
        graphLayer.path = path.cgPath
        graphLayer.strokeColor = UIColor.orange.cgColor
        graphLayer.fillColor = UIColor.clear.cgColor
        graphLayer.masksToBounds = true

        view.layer.addSublayer(graphLayer)
    }

    private func setupBindings() {
        viewModel.showSquareTimer
            .bind(to: square.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showCircleTimer
            .bind(to: circle.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.currentLookAtPoint.subscribe(onNext: { _ in  }).disposed(by: disposeBag)

        let height = view.frame.height

        viewModel.accelerationRelay.subscribe(onNext: { [weak self] acceleration in
            guard let acceleration = acceleration, let self = self else { return }

            let l = (acceleration.x.magnitudeSquared + acceleration.y.magnitudeSquared + acceleration.z.magnitudeSquared).squareRoot()
            let currentTimestamp = Date().timeIntervalSince(appStart)
            points.append(CGPoint(x: CGFloat(currentTimestamp) * timeIntervalXModifier , y: l * 100 + height * 0.75))
            self.drawGraph()
        }).disposed(by: disposeBag)
    }

}

