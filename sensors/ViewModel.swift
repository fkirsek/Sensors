//
//  ViewModel.swift
//  sensors
//
//  Created by Filip Kirsek on 2025-05-19.
//
import RxSwift


class ViewModel {
    let showSquareTimer: Observable<Bool>
    let showCircleTimer: Observable<Bool>
    let disposeBag = DisposeBag()

    init() {
        let baseTimer = Observable<Int>
            .interval(.milliseconds(200), scheduler: MainScheduler.instance)
        
        showSquareTimer = baseTimer.map { timePassed in
            timePassed % 20 != 9
        }

        showCircleTimer = baseTimer.map { timePassed in
            timePassed % 20 != 19
        }

    }
}
