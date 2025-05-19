//
//  ViewModel.swift
//  sensors
//
//  Created by Filip Kirsek on 2025-05-19.
//

import Foundation
import RxSwift
import ARKit
import CoreMotion

class ViewModel {
    let showSquareTimer: Observable<Bool>
    let showCircleTimer: Observable<Bool>
    let disposeBag = DisposeBag()

    let session = ARSession()
    let currentFaceTransform: Observable<simd_float4x4>

    let motionManager = CMMotionManager()
    let accelerationRelay = BehaviorSubject<CMAcceleration?>(value: nil)
    let updateInterval = 0.05

    private let dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    private let timestampFormatter = DateFormatter()

    init() {
        // MARK: Base timers

        timestampFormatter.dateFormat = dateFormat

        let baseTimer = Observable<Int>
            .interval(.milliseconds(200), scheduler: MainScheduler.instance)
        
        showSquareTimer = baseTimer.map { timePassed in
            timePassed % 20 != 9
        }.distinctUntilChanged()
        .do(onNext: { [timestampFormatter] isHidden in
            // log the event
            print("\(timestampFormatter.string(from: Date())): Square is hidden: \(isHidden)")
        })

        showCircleTimer = baseTimer.map { timePassed in
            timePassed % 20 != 19
        }.distinctUntilChanged()
        .do(onNext: { [timestampFormatter] isHidden in
            // log the event
            print("\(timestampFormatter.string(from: Date())): Circle is hidden: \(isHidden)")
        })

        // MARK: AR Face Tracking

        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = 1

        session.run(configuration)

        let faceAnchorObservable = baseTimer.map { [session] timePassed -> ARFaceAnchor? in
            for anchor in session.currentFrame?.anchors ?? [] {
                if let faceAnchor = anchor as? ARFaceAnchor {
                    return faceAnchor
                }
            }
            return nil
        }.compactMap { $0 }
        .do(onNext: { [timestampFormatter] faceAnchor in
            // log the event
            print("\(timestampFormatter.string(from: Date())): Face detected with transform \(faceAnchor.transform.debugDescription)")
        })

        currentFaceTransform = faceAnchorObservable.map { $0.transform }

        // MARK: CoreMotion

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self, timestampFormatter] data, error in
            guard error == nil,
                    let data = data else
            { return }
            print("\(timestampFormatter.string(from: Date())): Accelerometer update")
            self?.accelerationRelay.onNext(data.acceleration) // wrap accelerometer updates in rx
        }
    }
}
