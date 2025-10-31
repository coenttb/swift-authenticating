//
//  exports.swift
//  swift-authenticating
//
//  Created by Coen ten Thije Boonkkamp on 23/01/2025.
//

@_exported import AuthenticatingEmailAddress
@_exported import AuthenticatingURLRouting
@_exported import RFC_6750
@_exported import RFC_7617
@_exported import URLRouting

public typealias BearerAuth = RFC_6750.Bearer
public typealias BasicAuth = RFC_7617.Basic
