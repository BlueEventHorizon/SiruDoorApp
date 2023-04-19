//
//  DependencyInjectable.swift
//
//
//  Created by Katsuhiko Terada on 2023/02/06.
//

import Foundation

public protocol DependencyInjectable: AnyObject {
    associatedtype Dependency

    var dependency: Dependency! {
        get set
    }

    func resolve(dependency: Dependency)
}

extension DependencyInjectable {
    func resolve(dependency: Dependency) {
        self.dependency = dependency
    }
}
