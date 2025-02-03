//
//  ViewAppearance.swift
//  SynciOS
//
//  Created by Sergii D on 2/3/25.
//

protocol ViewAppearanceProviding {
    func didAppear()
    func didDisappear()
}

extension ViewAppearanceProviding {
    func didAppear() {}
    func didDisappear() {}
}
