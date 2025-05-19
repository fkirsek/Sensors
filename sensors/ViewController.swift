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
    let size = 50.0
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()

    let circleAppearedLabel = UILabel()
    var circleAppearedLabelXCoord = NSLayoutConstraint()
    var circleAppearedTimestamp = TimeInterval()

    let circleDisappearedLabel = UILabel()
    var circleDisappearedLabelXCoord = NSLayoutConstraint()

    let squareAppearedLabel = UILabel()
    var squareAppearedLabelXCoord = NSLayoutConstraint()
    var squareAppearedTimestamp = TimeInterval()

    let squareDisappearedLabel = UILabel()
    var squareDisappearedLabelXCoord = NSLayoutConstraint()

    let circleColor = UIColor.red
    let squareColor = UIColor.blue

    let graphLayer = CAShapeLayer()
    var points: [CGPoint] = []
    let timeIntervalXModifier = 100.0
    var maxCount = 0
    var width: CGFloat = 0
    var height: CGFloat = 0

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
        view.layer.addSublayer(graphLayer)

        square.autoCenterInSuperview()
        square.backgroundColor = squareColor
        square.autoSetDimensions(to: CGSize(width: size, height: size))
        square.isHidden = true

        circle.autoCenterInSuperview()
        circle.autoSetDimensions(to: CGSize(width: size, height: size))
        circle.backgroundColor = circleColor
        circle.layer.cornerRadius = size / 2
        circle.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        width = view.frame.width
        height = view.frame.height
        maxCount = Int(width * 0.5 / (viewModel.updateInterval * timeIntervalXModifier) )

        circleAppearedLabel.text = "Circle appeared"
        setupLabel(label: circleAppearedLabel, color: circleColor, constraint: &circleAppearedLabelXCoord)

        circleDisappearedLabel.text = "Circle disappeared"
        setupLabel(label: circleDisappearedLabel, color: circleColor, constraint: &circleDisappearedLabelXCoord)

        squareAppearedLabel.text = "Square appeared"
        setupLabel(label: squareAppearedLabel, color: squareColor, constraint: &squareAppearedLabelXCoord)

        squareDisappearedLabel.text = "Square disappeared"
        setupLabel(label: squareDisappearedLabel, color: squareColor, constraint: &squareDisappearedLabelXCoord)
    }

    private func setupLabel(label: UILabel, color: UIColor, constraint: inout NSLayoutConstraint) {
        label.textColor = color
        label.isHidden = true
        view.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .top, withInset: height * 0.25)
        constraint = label.autoPinEdge(.left, to: .left, of: view, withOffset: 0)
        label.font = .systemFont(ofSize: 8)

        let lineView = UIView()
        label.addSubview(lineView)
        lineView.autoPinEdge(.bottom, to: .top, of: label)
        lineView.autoPinEdge(.top, to: .top, of: view)
        lineView.autoSetDimension(.width, toSize: 1)
        lineView.backgroundColor = color
    }

    private func drawGraph() {
        let path = UIBezierPath()
        path.move(to: CGPointZero)

        //TODO: Clunky, move to ViewModel?
        let startInterval = points.first?.x ?? 0
        let graphPoints = points.map { CGPoint(x: $0.x - startInterval, y: $0.y)  }

        graphPoints.forEach { graphPoint in
            path.addLine(to: graphPoint)
        }
        path.move(to: CGPointZero)
        path.close()

        let frame = CGRect(x: 0, y: 0, width: width / 2, height: height / 4)
        graphLayer.frame = frame
        graphLayer.backgroundColor = UIColor.lightGray.cgColor
        graphLayer.path = path.cgPath
        graphLayer.strokeColor = UIColor.orange.cgColor
        graphLayer.fillColor = UIColor.clear.cgColor
        graphLayer.masksToBounds = true

        // Move labels
        circleAppearedLabelXCoord.constant = CGFloat(circleAppearedTimestamp) * timeIntervalXModifier - startInterval
        squareAppearedLabelXCoord.constant = CGFloat(squareAppearedTimestamp) * timeIntervalXModifier - startInterval
    }

    private func setupBindings() {
        viewModel.showSquareTimer
            .do(onNext: { [weak self] isHidden in
                guard let self = self else { return }
                if isHidden {
                    //squareDisappearedLabel.isHidden = false
                } else {
                    squareAppearedLabel.isHidden = false
                    squareAppearedTimestamp = Date().timeIntervalSince(appStart) //TODO: better to use the timer counter
                }
            })
            .bind(to: square.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showCircleTimer
            .do(onNext: { [weak self] isHidden in
                guard let self = self else { return }
                if isHidden {
                    //circleDisappearedLabel.isHidden = false
                } else {
                    circleAppearedLabel.isHidden = false
                    circleAppearedTimestamp = Date().timeIntervalSince(appStart) //TODO: better to use the timer counter
                }
            })
            .bind(to: circle.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.currentFaceTransform.subscribe(onNext: { _ in  }).disposed(by: disposeBag)

        viewModel.accelerationObservable
            .subscribe(onNext: { [weak self] acceleration in
                guard let self = self else { return }
                let l = (acceleration.x.magnitudeSquared + acceleration.y.magnitudeSquared + acceleration.z.magnitudeSquared).squareRoot()
                let currentTimestamp = Date().timeIntervalSince(appStart) //TODO: better to use the timer counter

                if points.count > self.maxCount {
                    points.removeFirst()
                }
                points.append(CGPoint(x: CGFloat(currentTimestamp) * timeIntervalXModifier , y: l * 100))
                self.drawGraph()
        }).disposed(by: disposeBag)
    }
}

