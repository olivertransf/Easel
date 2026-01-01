//
//  PreviewHelpers.swift
//  Easel
//
//  Created by Oliver Tran on 12/30/25.
//

import Foundation

extension CanvasUser {
    static func preview() -> CanvasUser {
        CanvasUser(
            id: "12345",
            name: "John Doe",
            sortable_name: "Doe, John",
            short_name: "John",
            login_id: "jdoe",
            email: "john.doe@example.com"
        )
    }
}


