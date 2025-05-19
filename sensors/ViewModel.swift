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
import os

class ViewModel {
    let baseTimerAllInterval = 10 // miliseconds
    let baseTimerIntervalShapes = 200 // miliseconds

    let showSquareTimer: Observable<Bool>
    let showCircleTimer: Observable<Bool>
    let disposeBag = DisposeBag()

    let session = ARSession()
    let currentFaceTransform: Observable<simd_float4x4>

    let motionManager = CMMotionManager()
    let accelerationObservable: Observable<CMAcceleration>
    let updateInterval = 0.01 // seconds, float

    private let dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    private let timestampFormatter = DateFormatter()

    let logger = Logger() // replace with a custom logging class to get the data sent 

    init() {
        // MARK: Base timers
        let timerRatio = baseTimerIntervalShapes / baseTimerAllInterval

        timestampFormatter.dateFormat = dateFormat

        let baseTimerAll = Observable<Int>
            .timer(.milliseconds(0) ,period: .milliseconds(baseTimerAllInterval), scheduler: MainScheduler.instance).share()

        let baseTimer = baseTimerAll.filter { $0 % timerRatio != 0 }.map { $0 / timerRatio }

        // TODO: 20, 9, 19 magic numbers
        showSquareTimer = baseTimer.map { timePassed in
            timePassed % 20 != 9
        }.distinctUntilChanged()
        .do(onNext: { [logger, timestampFormatter] isHidden in
            logger.info("\(timestampFormatter.string(from: Date())): Square is hidden: \(isHidden)")
        })

        showCircleTimer = baseTimer.map { timePassed in
            timePassed % 20 != 19
        }.distinctUntilChanged()
        .do(onNext: { [logger, timestampFormatter] isHidden in
            logger.info("\(timestampFormatter.string(from: Date())): Circle is hidden: \(isHidden)")
        })

        // MARK: AR Face Tracking

        let configuration = ARFaceTrackingConfiguration()
        configuration.isWorldTrackingEnabled = true
        session.run(configuration)

        let faceAnchorObservable = baseTimer.map { [session] timePassed -> ARFaceAnchor? in
            for anchor in session.currentFrame?.anchors ?? [] {
                if let faceAnchor = anchor as? ARFaceAnchor {
                    return faceAnchor
                }
            }
            return nil
        }.compactMap { $0 }

        currentFaceTransform = faceAnchorObservable
            .map { $0.transform }
            .distinctUntilChanged()
            .do(onNext: { [logger, timestampFormatter] transform in
                logger.info("\(timestampFormatter.string(from: Date())): Face detected with transform \(transform.debugDescription)")
            })

        // MARK: CoreMotion

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates()

        // MotionManager accelerometer has a fidelity of 10 milisecond,
        // so we will poll the latest data on the same timer to ensure
        // it is as close as possible to other timed events

        accelerationObservable = baseTimerAll.map { [weak motionManager] _ in
            let data = motionManager?.accelerometerData
            guard let data = data else { return nil }
            return data.acceleration
        }
        .compactMap { $0 }
        .do(onNext: { [logger, timestampFormatter] _ in
            logger.info("\(timestampFormatter.string(from: Date())): Accelerometer update")
        })
    }
}
