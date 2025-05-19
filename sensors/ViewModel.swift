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
    let currentLookAtPoint: Observable<simd_float3?>

    let motionManager = CMMotionManager()
    let accelerationRelay = BehaviorSubject<CMAcceleration?>(value: nil)

    private let dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    private let timestampFormatter = DateFormatter()

    init() {
        // MARK: Base timers

        timestampFormatter.dateFormat = dateFormat

        let baseTimer = Observable<Int>
            .interval(.milliseconds(200), scheduler: MainScheduler.instance)
        
        showSquareTimer = baseTimer.map { timePassed in
            timePassed % 20 != 9
        }.do(onNext: { [timestampFormatter] isHidden in
            if !isHidden {
                // log the event
                print("\(timestampFormatter.string(from: Date())): Square shown")

            }
        })

        showCircleTimer = baseTimer.map { timePassed in
            timePassed % 20 != 19
        }.do(onNext: { [timestampFormatter] isHidden in
            if !isHidden {
                // log the event
                print("\(timestampFormatter.string(from: Date())): Circle shown")
            }
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
        }.do(onNext: { [timestampFormatter] faceAnchor in
            if faceAnchor != nil {
                // log the event
                print("\(timestampFormatter.string(from: Date())): Face detected")
            }
        })

        currentLookAtPoint = faceAnchorObservable.map { $0?.lookAtPoint }

        // MARK: CoreMotion

        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { [weak self, timestampFormatter] data, error in
            guard error == nil,
                    let data = data else
            { return }
            print("\(timestampFormatter.string(from: Date())): Face detected")
            self?.accelerationRelay.onNext(data.acceleration) // wrap accelerometer updates in rx
        }
    }
}
